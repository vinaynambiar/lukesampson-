$cfgpath = "~/.scoop"
if(!(test-path $cfgpath)) {
	"{}" | out-file $cfgpath -encoding utf8
} 

function get_config($name) {
	return jq ".$name" (resolve-path $cfgpath)
}

function set_config($name, $val) {
	if($val -eq $null) {
		$cfg = jq "del(.$name)" (resolve-path $cfgpath)
	}
	else {
		$cfg = jq ". += {${name}: \`"$val\`"}" (resolve-path $cfgpath)
	}

	$cfg | out-file $cfgpath -encoding utf8
}

# setup proxy
$p = get_config 'proxy'
if($p) {
	try {
		$cred, $address = $p -split '@'
		if(!$address) {
			$address, $cred = $cred, $null # no credentials supplied
		}

		if($address -eq 'none') {
			[net.webrequest]::defaultwebproxy = $null
		} elseif($address -ne 'default') {
			[net.webrequest]::defaultwebproxy = new-object net.webproxy "http://$address"
		}

		if($cred -eq 'currentuser') {
			[net.webrequest]::defaultwebproxy.credentials = [net.credentialcache]::defaultcredentials
		} elseif($cred) {
			$user, $pass = $cred -split ':'
			[net.webrequest]::defaultwebproxy.credentials = new-object net.networkcredential($user, $pass)
		}
	} catch {
		warn "failed to use proxy '$p': $($_.exception.message)"
	}
}