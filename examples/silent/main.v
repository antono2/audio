// Demonstrates bounded voice reuse and duplicate-cue suppression without an audio device.
module main

import antono2.audio.playback
import os

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	if os.args.len != 2 {
		return error('Usage: silent <file.wav|file.ogg>')
	}
	mut audio := playback.new_audio(playback.AudioConfig{ null_backend: true, volume: 0 })!
	defer { audio.shutdown() }
	for id in ['left', 'right'] {
		audio.load(id, os.args[1], playback.SoundConfig{})!
	}
	mut voices := playback.spatial_voice_pool(['left', 'right'])!
	mut cues := playback.cue_watermark(0)
	for sequence in [u64(1), 1, 2, 3] {
		if cues.accept(sequence)! {
			id := voices.play(mut audio, [f32(1), 0, -2]!)!
			println('Cue ${sequence}: ${id}')
		}
	}
	assert audio.sound_count() == 2
	println('Two voices reused; duplicate cue ignored; no audio device opened.')
}
