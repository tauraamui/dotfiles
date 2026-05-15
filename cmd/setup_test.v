module main

import os

fn build_file_reader(mut read_file_path &string, mock_file_content string) FileReader {
	return fn [mut read_file_path, mock_file_content] (file_path string) !string {
		read_file_path = file_path
		return mock_file_content
	}
}

const mock_profile_content = '
	{
		"packages": [{ "name": "stow" }]
	}
'

fn test_resolve_user_profile() {
	mut read_file_path := ''
	expected_user_profile := UserProfile{
		packages: [
			UserPackage{ name: "stow" }
		]
	}
	assert resolve_user_profile(build_file_reader(mut &read_file_path, mock_profile_content), './profile.jsonc')! == expected_user_profile
	assert read_file_path == './profile.jsonc'
}

fn build_bin_resolver(bin_to_find string) BinResolver {
	return fn [bin_to_find] (bin_name string) !string {
		return if bin_to_find == bin_name { bin_name } else { error('unable to find: ${bin_name}') }
	}
}

fn test_detect_package_manager_resolves_first_found_bin() {
	assert detect_package_manager(build_bin_resolver('apt-get'), pkg_managers)?.name == 'apt'
	assert detect_package_manager(build_bin_resolver('dnf'), pkg_managers)?.name == 'dnf'
	assert detect_package_manager(build_bin_resolver('pacman'), pkg_managers)?.name == 'pacman'
	assert detect_package_manager(build_bin_resolver('zypper'), pkg_managers)?.name == 'zypper'
	assert detect_package_manager(build_bin_resolver('apk'), pkg_managers)?.name == 'apk'
}

fn build_cmd_runner(mut ran_cmd &string, mock_result os.Result) CmdRunner {
	return fn [mut ran_cmd, mock_result] (cmd string) os.Result {
		ran_cmd = cmd
		return mock_result
	}
}

fn test_update_package_manager_success() {
	mut cmd_run := ''
	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{}), apt_pkg_manager)!
	assert cmd_run == 'sudo apt-get update'

	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{}), pacman_pkg_manager)!
	assert cmd_run == 'sudo pacman -Sy'

	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{}), dnf_pkg_manager)!
	assert cmd_run == 'sudo dnf -y update'

	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{}), zypper_pkg_manager)!
	assert cmd_run == 'sudo zypper refresh'
}

@[assert_continues]
fn test_update_package_manager_failures() {
	mut cmd_run := ''
	mut err_msg := ''

	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{
		exit_code: 1
		output: 'test force fail for apt update run'
	}), apt_pkg_manager) or {
		err_msg = err.msg()
	}
	assert err_msg == 'apt errored: test force fail for apt update run'
	assert cmd_run == 'sudo apt-get update'

	cmd_run = ''
	err_msg = ''
	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{
		exit_code: 1
		output: 'test force fail for pacman update run'
	}), pacman_pkg_manager) or {
		err_msg = err.msg()
	}
	assert err_msg == 'pacman errored: test force fail for pacman update run'
	assert cmd_run == 'sudo pacman -Sy'

	cmd_run = ''
	err_msg = ''
	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{
		exit_code: 1
		output: 'test force fail for dnf update run'
	}), dnf_pkg_manager) or {
		err_msg = err.msg()
	}
	assert err_msg == 'dnf errored: test force fail for dnf update run'
	assert cmd_run == 'sudo dnf -y update'

	cmd_run = ''
	err_msg = ''
	update_package_manager(build_cmd_runner(mut &cmd_run, os.Result{
		exit_code: 1
		output: 'test force fail for zypper update run'
	}), zypper_pkg_manager) or {
		err_msg = err.msg()
	}
	assert err_msg == 'zypper errored: test force fail for zypper update run'
	assert cmd_run == 'sudo zypper refresh'
}


