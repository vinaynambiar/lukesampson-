. "${env:SCOOPDIR}\..\lib\json.ps1"

function empty_manifest {
    @{ 
    	"homepage" = ""; 
    	"license" = ""; 
    	"version" = ""; 
    	"url" = "";
      "hash" = ""; 
      "extract_dir" = ""; 
      "bin" = ""; 
      "depends" = "" 
    }
}

function manifest_path($app, $bucket) {
	"$(bucketdir $bucket)\$app.json"
}

function parse_json($path) {
	if(!(test-path $path)) { return $null }
	gc $path -encoding ascii | convertfrom-json -ea stop
}



function url_manifest($url) {
	$str = $null
	try {
		$str = (new-object net.webclient).downloadstring($url)
	} catch [system.management.automation.methodinvocationexception] {
		warn "error: $($_.exception.innerexception.message)"
	} catch {
		throw
	}
	if(!$str) { return $null }
	$str | convertfrom-json
}

function manifest_arch($json_arch) {
	$arch = @{}
	$archs = "32bit", "64bit"

	foreach ($arch_str in $archs) {
		if(($json_arch | jq "has(\`"$arch_str\`")") -eq "true") {
			write-debug "has $arch_str"
			$json_fragment = $json_arch | jq ".\`"$arch_str\`""
			$arch."$arch_str" = @{
				"url" = get_json_field "url" $json_fragment
				"hash" = get_json_field "hash" $json_fragment
			}
		}
	}

	$arch
}

function manifest($app, $bucket, $url) {
	if($url) { return url_manifest $url }
	$path = manifest_path $app $bucket

	$json = gc $path
	$manifest = empty_manifest
	$manifest.homepage = get_json_field "homepage" $json
	$manifest.license = get_json_field "license" $json
	$manifest.version = get_json_field "version" $json
	$manifest.extract_dir = get_json_field "extract_dir" $json
	$manifest.bin = get_json_field "bin" $json
	$manifest.checkver = get_json_field "checkver" $json
	$manifest.architecture = manifest_arch (get_json_field "architecture" $json)
	$manifest.depends = get_json_field "depends" $json

	$manifest
}

function save_installed_manifest($app, $bucket, $dir, $url) {
	if($url) { (new-object net.webclient).downloadstring($url) > "$dir\manifest.json" }
	else { cp (manifest_path $app $bucket) "$dir\manifest.json" }
}

function installed_manifest($app, $version, $global) {
	parse_json "$(versiondir $app $version $global)\manifest.json"
}

function save_install_info($info, $dir) {
	$nulls = $info.keys | ? { $info[$_] -eq $null }
	$nulls | % { $info.remove($_) } # strip null-valued

	$info | convertto-json | out-file "$dir\install.json"
}

function install_info($app, $version, $global) {
	$path = "$(versiondir $app $version $global)\install.json"
	if(!(test-path $path)) { return $null }
	parse_json $path
}

function default_architecture {
	if([intptr]::size -eq 8) { return "64bit" }
	"32bit"
}

function arch_specific($prop, $manifest, $architecture) {
	if($manifest.architecture) {
		$val = $manifest.architecture.$architecture.$prop
		if($val) { return $val } # else fallback to generic prop
	}

	if($manifest.$prop) { return $manifest.$prop }
}

function url($manifest, $arch) { arch_specific 'url' $manifest $arch }
function installer($manifest, $arch) { arch_specific 'installer' $manifest $arch }
function uninstaller($manifest, $arch) { arch_specific 'uninstaller' $manifest $arch }
function msi($manifest, $arch) { arch_specific 'msi' $manifest $arch }
function hash($manifest, $arch) { arch_specific 'hash' $manifest $arch }
function extract_dir($manifest, $arch) { arch_specific 'extract_dir' $manifest $arch}
function extract_to($manifest, $arch) { arch_specific 'extract_to' $manifest $arch}
