// Plays a decoded or streamed WAV/Ogg file on the default output at 15% gain.
// Stops after at most five seconds and releases the device on exit.
module main

import antono2.audio.playback
import os
import time

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	if os.args.len < 2 || os.args.len > 3 || (os.args.len == 3 && os.args[2] != '--stream') {
		return error('Usage: playback <file.wav|file.ogg> [--stream] (plays for at most five seconds)')
	}
	mut audio := playback.new_audio(playback.AudioConfig{ volume: 0.15 })!
	defer { audio.shutdown() }
	audio.load('example', os.args[1], playback.SoundConfig{ stream: '--stream' in os.args, spatial: false })!
	println('Playback device: ${audio.device_name()!}')
	info := audio.info('example')!
	println('${info.channels} channel(s), ${info.sample_rate} Hz; master gain 15%')
	audio.play('example')!
	for _ in 0 .. 100 {
		if !audio.is_playing('example')! {
			break
		}
		time.sleep(50 * time.millisecond)
	}
	audio.stop('example')!
}
