# resolve dependencies for the supplied apps, and sort into the correct order
function install_order($apps, $arch) {
	write-debug "entering install order for $apps..."
	$res = @()
	foreach($app in $apps) {
		foreach($dep in deps $app $arch) {
			if($res -notcontains $dep) { $res += $dep}
		}
		if($res -notcontains $app) { $res += $app }
	}
	write-debug "exiting install order..."
	return $res
}

# http://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
function deps($app, $arch) {
	write-debug "entering deps..."
	$resolved = new-object collections.arraylist
	dep_resolve $app $arch $resolved @()

	if($resolved.count -eq 1) { return @() } # no dependencies
	write-debug "exiting deps..."
	return $resolved[0..($resolved.count - 2)]
}

function dep_resolve($app, $arch, $resolved, $unresolved) {
	write-debug "entering dep resolve for $app..."
	$unresolved += $app

	write-debug "locating $app"
	$null, $manifest, $null, $null = locate $app
	if(!$manifest) { abort "couldn't find manifest for $app" }

	$deps = @(install_deps $manifest $arch) + @(runtime_deps $manifest) | select -uniq

	foreach($dep in $deps) {
		if($resolved -notcontains $dep -and $dep -ne $null) {
			if($unresolved -contains $dep) {
				abort "circular dependency detected: $app -> $dep"
			}
			dep_resolve $dep $arch $resolved $unresolved
		}
	}
	$resolved.add($app) > $null
	write-debug "exiting dep resolve..."
	$unresolved = $unresolved -ne $app # remove from unresolved
}

function runtime_deps($manifest) {
	if($manifest.depends) { return $manifest.depends }
}

function install_deps($manifest, $arch) {
	write-debug "entering install_deps..."
	$deps = @()

	if(requires_7zip $manifest $arch) { $deps += "7zip" }
	if($manifest.innosetup) { $deps += "innounp" }

	write-debug "exiting install_deps..."
	$deps
}