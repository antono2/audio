module playback

import math

// Bounded selection over caller-loaded voices. The pool owns only stable IDs;
// loading, unloading, source sharing and cue authority stay with the caller.
// Prefer an idle voice, otherwise replace the next voice in round-robin order.
pub struct SpatialVoicePool {
mut:
	voices []string
	cursor int
}

// spatial_voice_pool copies 1..64 unique, nonempty IDs; it does not load their sounds.
// Each ID must refer to a loaded voice in the Audio supplied to play.
pub fn spatial_voice_pool(voices []string) !SpatialVoicePool {
	if voices.len < 1 || voices.len > 64 {
		return error('spatial voice pool requires 1..64 voices')
	}
	mut seen := map[string]bool{}
	for id in voices {
		if id == '' || id in seen {
			return error('spatial voice IDs must be nonempty and unique')
		}
		seen[id] = true
	}
	return SpatialVoicePool{ voices: voices.clone() }
}

// voice_ids returns a copy; changing it cannot change pool membership.
pub fn (pool SpatialVoicePool) voice_ids() []string {
	return pool.voices.clone()
}

// No per-cue decoder creation or growing voice allocation. Advance selection
// only after successful position/play calls; errors remain explicit to the caller.
pub fn (mut pool SpatialVoicePool) play(mut device Audio, position [3]f32) !string {
	if pool.voices.len == 0 {
		return error('spatial voice pool is uninitialized')
	}
	for value in position {
		if math.is_nan(f64(value)) || math.is_inf(f64(value), 0) {
			return error('spatial voice position must be finite')
		}
	}
	mut selected := pool.cursor
	for offset in 0 .. pool.voices.len {
		candidate := (pool.cursor + offset) % pool.voices.len
		if !device.is_playing(pool.voices[candidate])! {
			selected = candidate
			break
		}
	}
	id := pool.voices[selected]
	device.set_sound_position(id, position[0], position[1], position[2])!
	device.play(id)!
	pool.cursor = (selected + 1) % pool.voices.len
	return id
}
