// Exercises bounded voice selection, replacement and failure handling with a silent engine.
module playback

import os
import math

fn test_spatial_voice_pool_idle_selection_capacity_replacement_and_errors() ! {
	mut device := new_audio(AudioConfig{ null_backend: true, volume: 0 })!
	defer { device.shutdown() }
	path := os.join_path(@VMODROOT, 'playback/testdata/tone440.ogg')
	for id in ['a', 'b', 'c'] {
		device.load(id, path, SoundConfig{ spatial: true })!
	}
	mut names := ['a', 'b', 'c']
	mut pool := spatial_voice_pool(names)!
	names[0] = 'changed'
	mut detached := pool.voice_ids()
	detached[0] = 'changed'
	assert pool.voice_ids() == ['a', 'b', 'c']
	assert pool.play(mut device, [f32(1), 2, 3]!)! == 'a'
	assert pool.play(mut device, [f32(1), 2, 3]!)! == 'b'
	assert pool.play(mut device, [f32(1), 2, 3]!)! == 'c'
	assert pool.play(mut device, [f32(1), 2, 3]!)! == 'a'
	device.stop('c')!
	assert pool.play(mut device, [f32(1), 2, 3]!)! == 'c'
	assert device.sound_count() == 3
	before := pool.cursor
	for value in [f32(math.inf(1)), f32(math.sqrt(-1))] {
		if _ := pool.play(mut device, [value, 0, 0]!) {
			assert false
		}
		assert pool.cursor == before
	}
	device.shutdown()
	if _ := pool.play(mut device, [f32(0), 0, 0]!) {
		assert false
	}
	assert pool.cursor == before
	for invalid in [[]string{}, [''], ['a', 'a'], []string{len: 65, init: 'voice_${index}'}] {
		if _ := spatial_voice_pool(invalid) {
			assert false
		}
	}
	mut empty := SpatialVoicePool{}
	if _ := empty.play(mut device, [f32(0), 0, 0]!) {
		assert false
	}
}
