module main

import os

struct UserPackage {
	name string
}

struct UserProfile {
	packages []UserPackage
}

fn resolve_user_profile(profile_path string) ?UserProfile {
	return none
}

struct PackageManager {
	name        string
	detect      []string
	update_cmd  string
	install_cmd string
}

const apt_pkg_manager = PackageManager{
	name: 'apt'
	detect: ['apt-get']
	update_cmd: 'sudo apt-get update'
	install_cmd: 'sudo apt-get install -y'
}

const pacman_pkg_manager = PackageManager{
	name:        'pacman'
	detect:      ['pacman']
	update_cmd:  'sudo pacman -Sy'
	install_cmd: 'sudo pacman -S --needed --noconfirm'
}

const dnf_pkg_manager = PackageManager{
	name: 'dnf'
	detect: ['dnf']
	update_cmd:  'sudo dnf -y update'
	install_cmd: 'sudo dnf -y install'
}

const zypper_pkg_manager = PackageManager{
	name:        'zypper'
	detect:      ['zypper']
	update_cmd:  'sudo zypper refresh'
	install_cmd: 'sudo zypper install -y'
}

const apk_pkg_manager = PackageManager{
	name:        'apk'
	detect:      ['apk']
	update_cmd:  'sudo apk update'
	install_cmd: 'sudo apk add --no-cache'
}

const pkg_managers = [
	apt_pkg_manager,
	pacman_pkg_manager,
	dnf_pkg_manager,
	zypper_pkg_manager,
	apk_pkg_manager,
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
	result := run_cmd(pkg_manager.update_cmd)
	if result.exit_code != 0 {
		return error('${pkg_manager.name} errored: ${result.output}')
	}
}

// This function internally decides which errors need to be raised to become panics
// and which can be just handled directly as tidier "handled" error output. In this way
// it provides the opportunity for some steps to fail but not derail the entire profile run.
fn run_with(
	resolve_bin BinResolver
	run_cmd     CmdRunner
) ! {
	println('resolving package manager...')
	resolved_pkg_manager := detect_package_manager(resolve_bin, pkg_managers) or {
		eprintln('failed to resolve package manager')
		exit(1)
	}

	println('resolved package manager: ${resolved_pkg_manager.name}')
	println('[${resolved_pkg_manager.name}] running package update...')
	update_package_manager(run_cmd, resolved_pkg_manager) or {
		eprintln('failed to update package manager: ${err}')
		exit(1)
	}
	println('[${resolved_pkg_manager.name}] updated packages successfully...')
}

fn main() {
	run_with(os.find_abs_path_of_executable, os.execute)!
}

