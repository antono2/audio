module main

import antono2.audio.playback
import os
import time

// Three short pulses at each position: left, centre, right. No microphone input.
fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	if os.args.len != 2 {
		return error('Usage: spatial <short-mono-file.wav|file.ogg> (six seconds, 15% master gain)')
	}
	mut audio := playback.new_audio(playback.AudioConfig{ volume: 0.15 })!
	defer { audio.shutdown() }
	audio.set_listener([f32(0), 0, 0]!, [f32(0), 0, -1]!, [f32(0), 1, 0]!)!
	audio.load('pulse', os.args[1], playback.SoundConfig{ min_distance: 5 })!
	info := audio.info('pulse')!
	if info.channels != 1 {
		return error('Use a mono file so the example demonstrates spatial positioning clearly')
	}
	for i, x in [f32(-4), 0, 4] {
		println(['Left', 'Centre', 'Right'][i])
		audio.set_sound_position('pulse', x, 0, -1)!
		for _ in 0 .. 3 {
			audio.play('pulse')!
			time.sleep(150 * time.millisecond)
			audio.stop('pulse')!
			time.sleep(250 * time.millisecond)
		}
		time.sleep(800 * time.millisecond)
	}
}
