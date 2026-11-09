module playback

import math
import os

fn test_nonfinite_controls_are_rejected_before_native_calls() ! {
	mut audio := new_audio(AudioConfig{ null_backend: true, volume: 0 })!
	defer { audio.shutdown() }
	path := os.join_path(@VMODROOT, 'playback/testdata/tone440.ogg')
	audio.load('tone', path, SoundConfig{})!
	for value in [f32(math.nan()), f32(math.inf(1)), f32(math.inf(-1))] {
		if mut invalid := new_audio(AudioConfig{ null_backend: true, volume: value }) {
			invalid.shutdown()
			assert false
		}
		if _ := audio.set_volume(value) {
			assert false
		}
		for config in [SoundConfig{ volume: value }, SoundConfig{ min_distance: value },
			SoundConfig{ max_distance: value }] {
			if _ := audio.load('invalid', path, config) {
				assert false
			}
			assert audio.sound_count() == 1
		}
		for position in [[value, f32(0), 0]!, [f32(0), value, 0]!, [f32(0), 0, value]!] {
			if _ := audio.set_sound_position('tone', position[0], position[1], position[2]) {
				assert false
			}
			if _ := audio.set_listener(position, [f32(0), 0, -1]!, [f32(0), 1, 0]!) {
				assert false
			}
			if _ := audio.set_listener([f32(0), 0, 0]!, position, [f32(0), 1, 0]!) {
				assert false
			}
			if _ := audio.set_listener([f32(0), 0, 0]!, [f32(0), 0, -1]!, position) {
				assert false
			}
		}
	}
	audio.set_volume(0.25)!
	audio.play('tone')!
	assert audio.is_playing('tone')!
}

fn test_decoded_and_streamed_voice_lifecycle_and_errors() ! {
	for streamed in [false, true] {
		mut audio := new_audio(AudioConfig{ null_backend: true, volume: 0 })!
		defer { audio.shutdown() }
		path := os.join_path(@VMODROOT, 'playback/testdata/tone440.ogg')
		audio.load('tone', path, SoundConfig{ stream: streamed, looping: true, spatial: false })!
		info := audio.info('tone')!
		assert info.channels == 1 && info.sample_rate == 48000
		if streamed {
			assert !info.length_known && info.frames == 0
		} else {
			assert info.length_known && info.frames == 4800
		}
		if _ := audio.load('tone', path, SoundConfig{}) {
			assert false
		}
		if _ := audio.load('missing', path + '.missing', SoundConfig{}) {
			assert false
		}
		if _ := audio.play('missing') {
			assert false
		}
		assert audio.sound_count() == 1
		audio.play('tone')!
		assert audio.is_playing('tone')!
		audio.stop('tone')!
		assert !audio.is_playing('tone')!
		audio.play('tone')!
		assert audio.is_playing('tone')!
		audio.shutdown()
		assert audio.sound_count() == 0
		if _ := audio.play('tone') {
			assert false
		}
		if _ := audio.load('tone', path, SoundConfig{}) {
			assert false
		}
		if _ := audio.set_volume(0.5) {
			assert false
		}
		audio.shutdown()
	}
}
