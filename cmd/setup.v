module main

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
		update_cmd: 'sudo apt-get update'
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

fn main() {
	println(pkg_managers)
}

