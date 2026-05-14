module main

import os

struct PackageManager {
	name        string
	detect      []string
	update_cmd  string
	install_cmd string
}

const pkg_managers = [
	PackageManager{
		name: 'apt'
		detect: ['apt-get']
		update_cmd: 'sudo sh -c "if command -v apt >/dev/null 2>&1; then apt update; else apt-get update; fi"'
		install_cmd: 'sudo apt-get install -y'
	},
	PackageManager{
		name: 'dnf'
		detect: ['dnf']
		update_cmd:  'sudo dnf -y update'
		install_cmd: 'sudo dnf -y install'
	},
	PackageManager{
		name:        'pacman'
		detect:      ['pacman']
		update_cmd:  'sudo pacman -Sy'
		install_cmd: 'sudo pacman -S --needed --noconfirm'
	},
	PackageManager{
		name:        'zypper'
		detect:      ['zypper']
		update_cmd:  'sudo zypper refresh'
		install_cmd: 'sudo zypper install -y'
	},
	PackageManager{
		name:        'apk'
		detect:      ['apk']
		update_cmd:  'sudo apk update'
		install_cmd: 'sudo apk add --no-cache'
	},
]

type BinResolver = fn (bin_name string) !string

fn detect_package_manager(resolve_bin BinResolver, managers_to_resolve []PackageManager) ?PackageManager {
	for pkg in managers_to_resolve {
		for bin_to_detect in pkg.detect {
			if (resolve_bin(bin_to_detect) or { '' }) != '' {
				return pkg
			}
		}
	}
	return none
}

type CmdRunner = fn (cmd string) os.Result

fn update_package_manager(run_cmd CmdRunner, pkg_manager PackageManager) ! {
	println(run_cmd(pkg_manager.update_cmd))
}

fn run_with(
	resolve_bin BinResolver
	run_cmd     CmdRunner
) ! {
	resolved_pkg_manager := detect_package_manager(resolve_bin, pkg_managers) or { return error('failed to resolve pkg manager') }
	update_result := run_cmd(resolved_pkg_manager.update_cmd)
	println(update_result)
}

fn main() {
	run_with(os.find_abs_path_of_executable, os.execute)!
}

