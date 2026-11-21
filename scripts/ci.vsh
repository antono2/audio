// Build the checked-out V compiler and validate audio with its matching C toolchain.
import audiotooling
import os

const usage = 'Usage: v run scripts/ci.vsh V_SOURCE'
const usage_status = 2
// The Windows bootstrap uses MinGW and a 32 MiB stack for the generated V compiler.
const mingw_gcc = 'x86_64-w64-mingw32-gcc.exe'
const windows_bootstrap_stack_bytes = 32 * 1024 * 1024
const mingw_pointer_warning = '-Wno-error=incompatible-pointer-types'

fn build_windows(compiler_source string) !string {
	cc := os.find_abs_path_of_executable(mingw_gcc)!
	ar := os.join_path(os.dir(cc), 'ar.exe')
	if !os.is_file(ar) {
		return error('Matching MinGW archiver was not found: ${ar}')
	}
	os.setenv('ANTONO2_AUDIO_CC', cc, true)
	os.setenv('ANTONO2_AUDIO_AR', ar, true)
	os.setenv('VFLAGS', '-gc none -cflags "${mingw_pointer_warning}"', true)
	bootstrap := os.join_path(compiler_source, 'v-bootstrap.exe')
	audiotooling.run(cc, ['-DCUSTOM_DEFINE_v1_fallback', '-std=c99', '-municode', '-w', '-o',
		bootstrap, 'vc/v_win.c', '-ladvapi32', '-lws2_32', '-lbcrypt',
		'-Wl,--stack=${windows_bootstrap_stack_bytes}'],
		work_directory: compiler_source
	)!
	audiotooling.run(bootstrap, ['-no-parallel', '-gc', 'none', '-cc', cc, '-cflags',
		mingw_pointer_warning, '-o', 'v.exe', 'cmd/v'],
		work_directory: compiler_source
	)!
	return cc
}

fn check(args []string) ! {
	if args in [['--help'], ['-h']] {
		println(usage)
		return
	}
	if args.len != 1 || args[0] == '' {
		return error_with_code(usage, usage_status)
	}
	compiler_source := os.abs_path(args[0])
	if !os.is_file(os.join_path(compiler_source, 'cmd', 'v', 'v.v')) {
		return error('Missing V compiler sources in ${compiler_source}')
	}
	// Make must write its own compiler, rather than the executable running this script.
	os.unsetenv('VEXE')
	cc := $if windows {
		build_windows(compiler_source)!
	} $else {
		audiotooling.run('make', ['-C', compiler_source, 'local=1', 'CC=cc', 'VFLAGS=-cc cc -gc none'])!
		'cc'
	}
	name := $if windows { 'v.exe' } $else { 'v' }
	os.setenv('ANTONO2_AUDIO_V_CC', cc, true)
	test_script := os.join_path(@VMODROOT, 'scripts', 'test.vsh')
	audiotooling.run(os.join_path(compiler_source, name), ['-cc', cc, 'run', test_script])!
}

check(os.args[1..]) or {
	eprintln(err)
	exit(if err.code() > 0 { err.code() } else { 1 })
}
