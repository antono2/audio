// Owns miniaudio engines and named voices behind the V playback API.
// Serialize wrapper calls and release native resources with shutdown(); build the native archive first.
module playback

import math

#flag -I @VMODROOT/thirdparty/miniaudio

#flag -I @VMODROOT/thirdparty/stb_vorbis

#flag linux @VMODROOT/.cache/native/libantono2_audio.a
#flag darwin @VMODROOT/.cache/native/libantono2_audio.a
#flag windows -L@VMODROOT/.cache/native
#flag windows -lantono2_audio

#flag linux -ldl

#flag linux -lpthread

#flag linux -lm

#flag darwin -framework CoreAudio

#flag darwin -framework AudioToolbox

#flag darwin -framework AudioUnit

#flag darwin -framework CoreFoundation

#flag windows -lole32

#flag windows -luuid

#flag windows -lwinmm

#include "stb_vorbis.h"

#include "miniaudio.h"

@[typedef]
struct C.ma_engine {}

@[typedef]
struct C.ma_engine_config {
mut:
	noDevice   u32
	channels   u32
	sampleRate u32
}

@[typedef]
struct C.ma_sound {}

@[typedef]
struct C.ma_device {}

fn C.ma_engine_config_init() C.ma_engine_config

fn C.ma_engine_init(config &C.ma_engine_config, engine &C.ma_engine) int

fn C.ma_engine_uninit(engine &C.ma_engine)

fn C.ma_engine_start(engine &C.ma_engine) int

fn C.ma_engine_stop(engine &C.ma_engine) int

fn C.ma_engine_get_device(engine &C.ma_engine) &C.ma_device

fn C.ma_engine_set_volume(engine &C.ma_engine, volume f32) int

fn C.ma_engine_listener_set_position(engine &C.ma_engine, listener u32, x f32, y f32, z f32)

fn C.ma_engine_listener_set_direction(engine &C.ma_engine, listener u32, x f32, y f32, z f32)

fn C.ma_engine_listener_set_world_up(engine &C.ma_engine, listener u32, x f32, y f32, z f32)

fn C.ma_sound_init_from_file(engine &C.ma_engine, path &char, flags u32, group voidptr, fence voidptr, sound &C.ma_sound) int

fn C.ma_sound_uninit(sound &C.ma_sound)

fn C.ma_sound_start(sound &C.ma_sound) int

fn C.ma_sound_stop(sound &C.ma_sound) int

fn C.ma_sound_seek_to_pcm_frame(sound &C.ma_sound, frame u64) int

fn C.ma_sound_set_volume(sound &C.ma_sound, volume f32)

fn C.ma_sound_get_volume(sound &C.ma_sound) f32

fn C.ma_sound_set_position(sound &C.ma_sound, x f32, y f32, z f32)

fn C.ma_sound_set_min_distance(sound &C.ma_sound, distance f32)

fn C.ma_sound_set_max_distance(sound &C.ma_sound, distance f32)

fn C.ma_sound_set_looping(sound &C.ma_sound, looping u32)

fn C.ma_sound_is_playing(sound &C.ma_sound) u32

fn C.ma_sound_get_data_format(sound &C.ma_sound, format voidptr, channels &u32, sample_rate &u32, channel_map voidptr, channel_map_capacity usize) int

fn C.ma_sound_get_length_in_pcm_frames(sound &C.ma_sound, length &u64) int

fn C.ma_device_get_name(device &C.ma_device, device_type int, name &char, name_capacity usize,
	length &usize) int

fn C.ma_result_description(result int) &char

fn C.ma_version_string() &char

const ma_success = 0
const ma_not_implemented = -29
const ma_sound_flag_stream = u32(0x00000001)
const ma_sound_flag_decode = u32(0x00000002)
const ma_sound_flag_no_spatialization = u32(0x00004000)

// AudioConfig selects the default device or a silent engine that does not advance playback.
// Master gain must be finite and in [0, 1].
pub struct AudioConfig {
pub:
	null_backend bool
	volume       f32 = 1
}

// SoundConfig selects decoded/streamed loading, looping and spatialization.
// Gains are finite [0, 1]; distances use the same units as positions, with 0 < min <= max.
pub struct SoundConfig {
pub:
	stream       bool
	spatial      bool = true
	looping      bool
	volume       f32 = 1
	min_distance f32 = 1
	max_distance f32 = 100
}

// SoundInfo reports sample rate in Hz and length in PCM frames, not individual channel samples.
// frames is usable only when length_known is true.
pub struct SoundInfo {
pub:
	channels     u32
	sample_rate  u32
	frames       u64
	length_known bool
}

// Audio owns native engine and sound allocations; do not copy it into independent owners.
// Serialize control calls and call shutdown when finished.
@[heap]
pub struct Audio {
mut:
	engine             &C.ma_engine = unsafe { nil }
	engine_initialized bool
	null_backend       bool
	sounds             map[string]&C.ma_sound
}

// new_audio creates an engine or returns a validation/native initialization error.
// The caller owns the returned instance and must call shutdown.
pub fn new_audio(config AudioConfig) !&Audio {
	if !finite(config.volume) || config.volume < 0 || config.volume > 1 {
		return error('audio volume must be in [0, 1]')
	}
	mut audio := &Audio{
		engine:       &C.ma_engine{}
		null_backend: config.null_backend
		sounds:       map[string]&C.ma_sound{}
	}
	mut engine_config := C.ma_engine_config_init()
	if config.null_backend {
		engine_config.noDevice = 1
		engine_config.channels = 2
		engine_config.sampleRate = 48_000
	}
	result := C.ma_engine_init(&engine_config, audio.engine)
	if result != ma_success {
		audio.free_storage()
		return miniaudio_error('initialize audio engine', result)
	}
	audio.engine_initialized = true
	audio.set_volume(config.volume) or {
		audio.shutdown()
		return err
	}
	return audio
}

// sound_count counts loaded voices, including stopped ones; shutdown clears them.
pub fn (audio &Audio) sound_count() int {
	return audio.sounds.len
}

// device_name returns a copied device name, or "none" for the silent backend.
// Returns an error after shutdown or if the native device query fails.
pub fn (audio &Audio) device_name() !string {
	if !audio.engine_initialized {
		return error('audio engine is not initialized')
	}
	if audio.null_backend {
		return 'none'
	}
	device := C.ma_engine_get_device(audio.engine)
	if isnil(device) {
		return error('audio engine has no playback device')
	}
	mut name := []u8{len: 512}
	mut length := usize(0)
	result := C.ma_device_get_name(device, 1, unsafe { &char(name.data) }, name.len, &length)
	ensure_success(result, 'query playback device name')!
	return unsafe { (&char(name.data)).vstring() }.clone()
}

// version returns the linked miniaudio version, not the V package version.
pub fn version() string {
	return unsafe { C.ma_version_string().vstring() }.clone()
}

// load adds one owned voice without starting playback; IDs must be nonempty and unique.
// File/decoder and configuration failures return errors without registering the voice.
// Keep streamed files available for the lifetime of their loaded voices.
pub fn (mut audio Audio) load(id string, path string, config SoundConfig) ! {
	if !audio.engine_initialized {
		return error('audio engine is not initialized')
	}
	if id == '' {
		return error('sound id must not be empty')
	}
	if id in audio.sounds {
		return error('sound `${id}` is already loaded')
	}
	if !finite(config.volume) || !finite(config.min_distance) || !finite(config.max_distance)
		|| config.volume < 0 || config.volume > 1 || config.min_distance <= 0
		|| config.max_distance < config.min_distance {
		return error('sound `${id}` has invalid volume or distance limits')
	}
	mut flags := if config.stream { ma_sound_flag_stream } else { ma_sound_flag_decode }
	if !config.spatial {
		flags |= ma_sound_flag_no_spatialization
	}
	handle := &C.ma_sound{}
	result := C.ma_sound_init_from_file(audio.engine, path.str, flags, unsafe { nil }, unsafe { nil }, handle)
	if result != ma_success {
		unsafe { free(handle) }
		return miniaudio_error('load sound `${id}` from `${path}`', result)
	}
	C.ma_sound_set_volume(handle, config.volume)
	C.ma_sound_set_looping(handle, u32(config.looping))
	if config.spatial {
		C.ma_sound_set_min_distance(handle, config.min_distance)
		C.ma_sound_set_max_distance(handle, config.max_distance)
	}
	audio.sounds[id] = handle
}

// play stops and rewinds a loaded voice before starting it; it does not resume from a pause.
// Missing IDs or native stop/seek/start failures return errors.
pub fn (mut audio Audio) play(id string) ! {
	handle := audio.sound(id)!
	ensure_success(C.ma_sound_stop(handle), 'stop sound `${id}` before replay')!
	ensure_success(C.ma_sound_seek_to_pcm_frame(handle, 0), 'rewind sound `${id}`')!
	ensure_success(C.ma_sound_start(handle), 'play sound `${id}`')!
}

// stop halts a loaded voice without unloading it; unknown IDs and native failures return errors.
pub fn (mut audio Audio) stop(id string) ! {
	ensure_success(C.ma_sound_stop(audio.sound(id)!), 'stop sound `${id}`')!
}

// is_playing queries a loaded voice; the silent backend does not advance its playback clock.
pub fn (audio &Audio) is_playing(id string) !bool {
	return C.ma_sound_is_playing(audio.sound(id)!) != 0
}

// info queries a loaded voice; unsupported streamed length is reported as unknown rather than an error.
// Other native query failures and unknown IDs return errors.
pub fn (audio &Audio) info(id string) !SoundInfo {
	handle := audio.sound(id)!
	mut channels := u32(0)
	mut sample_rate := u32(0)
	mut frames := u64(0)
	ensure_success(C.ma_sound_get_data_format(handle, unsafe { nil }, &channels, &sample_rate, unsafe { nil }, 0), 'query sound `${id}` format')!
	length_result := C.ma_sound_get_length_in_pcm_frames(handle, &frames)
	// Some streamed decoders cannot report a total length without decoding the
	// whole file. Preserve usable format information and expose that distinction.
	if length_result != ma_not_implemented {
		ensure_success(length_result, 'query sound `${id}` length')!
	}
	return SoundInfo{
		channels:     channels
		sample_rate:  sample_rate
		frames:       if length_result == ma_success { frames } else { 0 }
		length_known: length_result == ma_success
	}
}

// set_sound_position sets finite coordinates in the same units as the listener and distance limits.
// Positioning affects spatial voices; an unknown ID returns an error.
pub fn (mut audio Audio) set_sound_position(id string, x f32, y f32, z f32) ! {
	if !finite(x) || !finite(y) || !finite(z) {
		return error('sound position must be finite')
	}
	C.ma_sound_set_position(audio.sound(id)!, x, y, z)
}

// set_listener updates listener zero; coordinates and orientation components must be finite.
// The caller supplies meaningful forward/up vectors; this wrapper does not normalize them.
pub fn (mut audio Audio) set_listener(position [3]f32, forward [3]f32, up [3]f32) ! {
	if !audio.engine_initialized {
		return error('audio engine is not initialized')
	}
	for values in [position, forward, up] {
		for value in values {
			if !finite(value) {
				return error('listener position and orientation must be finite')
			}
		}
	}
	C.ma_engine_listener_set_position(audio.engine, 0, position[0], position[1], position[2])
	C.ma_engine_listener_set_direction(audio.engine, 0, forward[0], forward[1], forward[2])
	C.ma_engine_listener_set_world_up(audio.engine, 0, up[0], up[1], up[2])
}

// set_volume sets finite master gain in [0, 1]; the engine must still be initialized.
pub fn (mut audio Audio) set_volume(volume f32) ! {
	if !finite(volume) || volume < 0 || volume > 1 {
		return error('audio volume must be in [0, 1]')
	}
	if !audio.engine_initialized {
		return error('audio engine is not initialized')
	}
	ensure_success(C.ma_engine_set_volume(audio.engine, volume), 'set audio volume')!
}

// Change one loaded voice without rebuilding its decoder or changing the
// engine's master gain. This is authored runtime policy, not generated binding.
pub fn (mut audio Audio) set_sound_volume(id string, volume f32) ! {
	if !finite(volume) || volume < 0 || volume > 1 {
		return error('sound volume must be finite and in [0, 1]')
	}
	C.ma_sound_set_volume(audio.sound(id)!, volume)
}

// set_paused stops or starts the whole output device, preserving loaded voices.
// It is a no-op for an initialized silent engine; native device failures return errors.
pub fn (mut audio Audio) set_paused(paused bool) ! {
	if !audio.engine_initialized {
		return error('audio engine is not initialized')
	}
	if audio.null_backend {
		return
	}
	result := if paused { C.ma_engine_stop(audio.engine) } else { C.ma_engine_start(audio.engine) }
	ensure_success(result, if paused { 'pause audio engine' } else { 'resume audio engine' })!
}

// shutdown releases all loaded sounds and engine storage; repeated calls are safe.
// This instance cannot be reinitialized; create a new Audio to resume use.
pub fn (mut audio Audio) shutdown() {
	for _, handle in audio.sounds {
		C.ma_sound_uninit(handle)
		unsafe { free(handle) }
	}
	audio.sounds.clear()
	if audio.engine_initialized {
		C.ma_engine_uninit(audio.engine)
		audio.engine_initialized = false
	}
	audio.free_storage()
}

fn (audio &Audio) sound(id string) !&C.ma_sound {
	return audio.sounds[id] or { return error('sound `${id}` is not loaded') }
}

fn (mut audio Audio) free_storage() {
	if !isnil(audio.engine) {
		unsafe { free(audio.engine) }
		audio.engine = unsafe { nil }
	}
}

fn ensure_success(result int, operation string) ! {
	if result != ma_success {
		return miniaudio_error(operation, result)
	}
}

fn finite(value f32) bool {
	return !math.is_nan(value) && !math.is_inf(value, 0)
}

fn miniaudio_error(operation string, result int) IError {
	description := unsafe { C.ma_result_description(result).vstring() }
	return error('${operation}: ${description} (${result})')
}
