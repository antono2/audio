// Run build and validation commands with literal arguments and inherited diagnostics.
module audiotooling

import os

@[params]
pub struct RunOptions {
pub:
	work_directory string
}

pub fn run(program string, args []string, options RunOptions) ! {
	executable := if os.is_file(program) {
		os.abs_path(program)
	} else {
		os.find_abs_path_of_executable(program)!
	}
	mut process := os.new_process(executable)
	defer { process.close() }
	if options.work_directory != '' {
		process.set_work_folder(options.work_directory)
	}
	process.set_args(args)
	process.run()
	process.wait()
	if process.code != 0 {
		return error('${program} ${args.join(' ')} exited with status ${process.code}')
	}
}
