. "${env:SCOOPDIR}\..\lib\json.ps1"

$cfgpath = "~/.scoop"
if(!(test-path $cfgpath)) {
	"{}" | out-file $cfgpath -encoding utf8
} 

$cfg = json_to_hashtable (gc $cfgpath)

function get_config($name) {
	$cfg.$name
}

function set_config($name, $val) {
	$json = (gc $cfgpath)
	$json = json_set $name $val $json

	$json | out-file $cfgpath -encoding utf8
}

# setup proxy
$p = get_config 'proxy'
if($p) {
	write-debug "proxy found"
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