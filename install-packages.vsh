#!/usr/bin/env -S v run

import os
import flag

struct Manager {
	name        string
	detect      []string
	update_cmd  string
	install_cmd string
}

struct PackageOverride {
	manager string
	name    string
}

struct PackageSpec {
	id           string
	default_name string
	overrides    []PackageOverride
}

struct GoTool {
	name   string
	module string
}

const managers = [
	Manager{
		name:        'apt'
		detect:      ['apt-get']
		update_cmd:  'sudo apt-get update'
		install_cmd: 'sudo apt-get install -y'
	},
	Manager{
		name:        'dnf'
		detect:      ['dnf']
		update_cmd:  'sudo dnf -y update'
		install_cmd: 'sudo dnf -y install'
	},
	Manager{
		name:        'pacman'
		detect:      ['pacman']
		update_cmd:  'sudo pacman -Sy'
		install_cmd: 'sudo pacman -S --needed --noconfirm'
	},
	Manager{
		name:        'zypper'
		detect:      ['zypper']
		update_cmd:  'sudo zypper refresh'
		install_cmd: 'sudo zypper install -y'
	},
	Manager{
		name:        'apk'
		detect:      ['apk']
		update_cmd:  'sudo apk update'
		install_cmd: 'sudo apk add --no-cache'
	},
]

const package_specs = [
	PackageSpec{
		id:           'stow'
		default_name: 'stow'
	},
	PackageSpec{
		id:           'git'
		default_name: 'git'
	},
	PackageSpec{
		id:           'lazygit'
		default_name: 'lazygit'
	},
	PackageSpec{
		id:           'htop'
		default_name: 'htop'
	},
	PackageSpec{
		id:           'gnupg'
		default_name: 'gnupg'
	},
	PackageSpec{
		id:           'pinentry'
		default_name: 'pinentry'
		overrides:    [
			PackageOverride{
				manager: 'apt'
				name:    'pinentry-curses'
			},
			PackageOverride{
				manager: 'dnf'
				name:    'pinentry-curses'
			},
			PackageOverride{
				manager: 'zypper'
				name:    'pinentry-curses'
			},
		]
	},
	PackageSpec{
		id:           'gawk'
		default_name: 'gawk'
	},
	PackageSpec{
		id:           'wget'
		default_name: 'wget'
	},
	PackageSpec{
		id:           'xdotool'
		default_name: 'xdotool'
	},
	PackageSpec{
		id:           'go'
		default_name: 'go'
		overrides:    [
			PackageOverride{
				manager: 'apt'
				name:    'golang'
			},
			PackageOverride{
				manager: 'dnf'
				name:    'golang'
			},
		]
	},
	PackageSpec{
		id:           'github-cli'
		default_name: 'gh'
		overrides:    [
			PackageOverride{
				manager: 'pacman'
				name:    'github-cli'
			},
			PackageOverride{
				manager: 'apk'
				name:    'github-cli'
			},
		]
	},
	PackageSpec{
		id:           'httpie'
		default_name: 'httpie'
	},
	PackageSpec{
		id:           'ripgrep'
		default_name: 'ripgrep'
	},
	PackageSpec{
		id:           'neovim'
		default_name: 'neovim'
	},
	PackageSpec{
		id:           'tmux'
		default_name: 'tmux'
	},
	PackageSpec{
		id:           'fish'
		default_name: 'fish'
	},
	PackageSpec{
		id:           'starship'
		default_name: 'starship'
	},
	PackageSpec{
		id:           'fzf'
		default_name: 'fzf'
	},
]

const go_tools = [
	GoTool{
		name:   'crush'
		module: 'github.com/charmbracelet/crush@latest'
	},
	GoTool{
		name:   'goimports'
		module: 'golang.org/x/tools/cmd/goimports@latest'
	},
	GoTool{
		name:   'gofumpt'
		module: 'mvdan.cc/gofumpt@latest'
	},
	GoTool{
		name:   'gotestsum'
		module: 'gotest.tools/gotestsum@latest'
	},
	GoTool{
		name:   'sqlc'
		module: 'github.com/sqlc-dev/sqlc/cmd/sqlc@latest'
	},
	GoTool{
		name:   'scc'
		module: 'github.com/boyter/scc/v3@latest'
	},
	GoTool{
		name:   'invoice'
		module: 'github.com/maaslalani/invoice@latest'
	},
	GoTool{
		name:   'svu'
		module: 'github.com/caarlos0/svu@latest'
	},
	GoTool{
		name:   'task'
		module: 'github.com/go-task/task/v3/cmd/task@latest'
	},
]

fn (spec PackageSpec) name_for(manager string) string {
	for override in spec.overrides {
		if override.manager == manager {
			return override.name
		}
	}
	return spec.default_name
}

fn detect_manager(force string) !Manager {
	if force.len > 0 {
		return get_manager(force)
	}
	for manager in managers {
		for bin in manager.detect {
			if (os.find_abs_path_of_executable(bin) or { '' }) != '' {
				return manager
			}
		}
	}
	return error('unable to determine package manager')
}

fn get_manager(name string) !Manager {
	for manager in managers {
		if manager.name == name {
			return manager
		}
	}
	return error('unknown package manager ${name}')
}

fn package_names_for_manager(manager string) []string {
	mut names := []string{}
	for spec in package_specs {
		pkg_name := spec.name_for(manager)
		if pkg_name.len == 0 {
			continue
		}
		if names.contains(pkg_name) {
			continue
		}
		names << pkg_name
	}
	return names
}

fn run_cmd(cmd string, dry bool) ! {
	println(cmd)
	if dry {
		return
	}
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn install_system_packages(manager Manager, dry bool) ! {
	names := package_names_for_manager(manager.name)
	if names.len == 0 {
		return
	}
	if manager.update_cmd.len > 0 {
		run_cmd(manager.update_cmd, dry)!
	}
	cmd := '${manager.install_cmd} ${names.join(' ')}'
	run_cmd(cmd, dry)!
}

fn install_go_packages(dry bool) {
	if (os.find_abs_path_of_executable('go') or { '' }) == '' {
		eprintln('go not found in PATH, skipping go tool installation')
		return
	}
	mut failures := []string{}
	for tool in go_tools {
		cmd := 'GO111MODULE=on go install ${tool.module}'
		run_cmd(cmd, dry) or {
			failures << tool.name
			continue
		}
	}
	if failures.len > 0 {
		eprintln('failed to install: ${failures.join(', ')}')
	}
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('install-packages')
	apply := fp.bool('apply', `a`, false, 'execute commands instead of printing them')
	manager_override := fp.string('manager', `m`, '', 'force a package manager to use')
	skip_go := fp.bool('skip-go', 0, false, 'skip installing Go-based tools')
	rest := fp.finalize() or {
		eprintln(err.msg())
		return
	}
	mut leftovers := []string{}
	for arg in rest {
		if arg == os.args[0] {
			continue
		}
		leftovers << arg
	}
	if leftovers.len > 0 {
		eprintln('unexpected arguments: ${leftovers.join(' ')}')
		return
	}
	dry_run := !apply
	manager := detect_manager(manager_override) or {
		eprintln(err.msg())
		return
	}
	println('using package manager: ${manager.name}')
	install_system_packages(manager, dry_run) or {
		eprintln('system package installation failed: ${err.msg()}')
		return
	}
	if skip_go {
		return
	}
	install_go_packages(dry_run)
}
