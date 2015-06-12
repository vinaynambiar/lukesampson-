# Usage: scoop depends <app>
# Summary: List dependencies for an app

. "$($env:SCOOPDIR)\..\lib\depends.ps1"
. "$($env:SCOOPDIR)\..\lib\install.ps1"
. "$($env:SCOOPDIR)\..\lib\manifest.ps1"
. "$($env:SCOOPDIR)\..\lib\buckets.ps1"
. "$($env:SCOOPDIR)\..\lib\getopt.ps1"
. "$($env:SCOOPDIR)\..\lib\decompress.ps1"
. "$($env:SCOOPDIR)\..\lib\config.ps1"
. "$($env:SCOOPDIR)\..\lib\help.ps1"

reset_aliases

$opt, $apps, $err = getopt $args 'a:' 'arch='
$app = $apps[0]

if(!$app) { "<app> missing"; my_usage; exit 1 }

$architecture = ensure_architecture ($opt.a + $opt.architecture)

$deps = @(deps $app $architecture)
if($deps) {
	$deps[($deps.length - 1)..0]
}