// Checks per-voice gain changes and errors without opening an output device or reloading decoders.
module playback

import math
import os

fn test_loaded_voice_gain_without_decoder_reload_and_invalid_values() ! {
	mut device := new_audio(AudioConfig{ null_backend: true, volume: 0 })!
	defer { device.shutdown() }
	device.load('tone', os.join_path(@VMODROOT, 'playback', 'testdata', 'tone440.ogg'), SoundConfig{})!
	before := device.info('tone')!
	for volume in [f32(0), 0.001, 0.5, 1] {
		device.set_sound_volume('tone', volume)!
		assert C.ma_sound_get_volume(device.sound('tone')!) == volume
		assert device.info('tone')! == before && device.sound_count() == 1
	}
	for volume in [f32(-1), 2, f32(math.nan()), f32(math.inf(1))] {
		if _ := device.set_sound_volume('tone', volume) {
			assert false
		}
	}
	if _ := device.set_sound_volume('missing', 0.5) {
		assert false
	}
	device.shutdown()
	if _ := device.set_sound_volume('tone', 0.5) {
		assert false
	}
}
