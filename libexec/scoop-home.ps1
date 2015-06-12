# Usage: scoop home <app>
# Summary: Opens the app homepage
param($app)

. "$($env:SCOOPDIR)\..\lib\core.ps1"
. "$($env:SCOOPDIR)\..\lib\help.ps1"
. "$($env:SCOOPDIR)\..\lib\manifest.ps1"
. "$($env:SCOOPDIR)\..\lib\buckets.ps1"

reset_aliases

if($app) {
    $manifest, $bucket = find_manifest $app
    if($manifest) {
        if([string]::isnullorempty($manifest.homepage)) {
            abort "could not find homepage in manifest for '$app'"
        }
        start $manifest.homepage
    }
    else {
        abort "could not find manifest for '$app'"
    }
} else { my_usage }

exit 0