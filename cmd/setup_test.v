module main

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


