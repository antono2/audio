module playback

import os

fn test_null_audio_lifecycle_is_silent_and_idempotent() {
	mut device := new_audio(AudioConfig{
		null_backend: true
		volume:       0
	}) or { panic(err) }
	assert device.sound_count() == 0
	device_name := device.device_name() or { panic(err) }
	assert device_name == 'none'
	device.set_listener([f32(0), 1.7, 0]!, [f32(0), 0, -1]!, [f32(0), 1, 0]!) or {
		panic(err)
	}
	device.set_paused(true) or { panic(err) }
	device.set_paused(false) or { panic(err) }
	device.shutdown()
	device.shutdown()
}

fn test_audio_rejects_invalid_volume_and_missing_sound() {
	new_audio(AudioConfig{
		null_backend: true
		volume:       2
	}) or {
		assert err.msg().contains('[0, 1]')
		return
	}
	assert false
}

fn test_generated_ogg_decodes_through_null_engine() {
	mut audio := new_audio(AudioConfig{
		null_backend: true
		volume:       0
	}) or { panic(err) }
	defer {
		audio.shutdown()
	}
	path := os.join_path(@VMODROOT, 'playback', 'testdata', 'tone440.ogg')
	audio.load('tone', path, SoundConfig{
		stream:  false
		spatial: true
	}) or { panic(err) }
	info := audio.info('tone') or { panic(err) }
	assert info.channels == 1
	assert info.sample_rate == 48000
	assert info.frames == 4800
	audio.set_sound_position('tone', 1, 2, 3) or { panic(err) }
	audio.play('tone') or { panic(err) }
	assert audio.is_playing('tone') or { panic(err) }
	audio.stop('tone') or { panic(err) }
	assert audio.sound_count() == 1
}
