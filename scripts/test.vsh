#!/usr/bin/env -S v run
// Validates the package in an isolated module layout with both supported compiler modes.
// Builds all examples but runs only the silent one; no audio device is opened.

import os
import time

const package_root = @VMODROOT

fn main() {
	run_validation() or {
		eprintln(err)
		exit(1)
	}
}

fn run_validation() ! {
	os.setenv('V_MACOS_V3_NO_FALLBACK', '1', true)
	if os.getenv('VJOBS') == '' { os.setenv('VJOBS', '2', true) }
	cc := os.getenv('ANTONO2_AUDIO_V_CC')
	// The pinned compiler can omit native typedef includes in cached modules.
	// Compile complete translation units; keep strict new-compiler execution.
	compiler := os.quoted_path(@VEXE) + ' -nocache' + if cc == '' {
		''
	} else {
		' -cc ' + os.quoted_path(cc)
	}
	run('${compiler} run ${os.quoted_path(os.join_path(package_root, 'scripts/build_native_audio.vsh'))}')!
	temporary := os.join_path(os.temp_dir(), 'antono2-audio-test-${os.getpid()}-${time.now().unix_milli()}')
	module_root := os.join_path(temporary, 'antono2', 'audio')
	os.mkdir_all(module_root)!
	defer { os.rmdir_all(temporary) or { eprintln(err) } }
	for directory in ['playback', 'thirdparty', 'examples', '.cache/native'] {
		os.mkdir_all(os.dir(os.join_path(module_root, directory)))!
		os.cp_all(os.join_path(package_root, directory), os.join_path(module_root, directory), true)!
	}
	os.cp(os.join_path(package_root, 'v.mod'), os.join_path(module_root, 'v.mod'))!
	prior := os.getenv('VMODULES')
	os.setenv('VMODULES', temporary, true)
	defer { os.setenv('VMODULES', prior, true) }
	extension := $if windows { '.exe' } $else { '' }
	for flags in ['', '-new-compiler'] {
		run('${compiler} ${flags} test ${os.quoted_path(os.join_path(module_root, 'playback'))}')!
		for example in ['silent', 'playback', 'spatial'] {
			output := os.join_path(temporary, example + extension)
			run('${compiler} ${flags} -o ${os.quoted_path(output)} ${os.quoted_path(os.join_path(module_root, 'examples', example))}')!
			if example == 'silent' {
				run('${os.quoted_path(output)} ${os.quoted_path(os.join_path(module_root, 'playback/testdata/tone440.ogg'))}')!
			}
		}
	}
	println('Both compiler modes, isolated imports and silent example passed.')
}

fn run(command string) ! {
	result := os.execute(command)
	print(result.output)
	if result.exit_code != 0 {
		return error('validation command failed (${result.exit_code}): ${command}')
	}
}
