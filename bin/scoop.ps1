param($cmd)

set-strictmode -off

function scriptdir {
  $scriptDir = Get-Variable PSScriptRoot -ErrorAction SilentlyContinue | ForEach-Object { $_.Value }
  if (!$scriptDir) {
    if ($MyInvocation.MyCommand.Path) {
      $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
    }
  }
  if (!$scriptDir) {
    if ($ExecutionContext.SessionState.Module.Path) {
      $scriptDir = Split-Path (Split-Path $ExecutionContext.SessionState.Module.Path)
    }
  }
  if (!$scriptDir) {
    $scriptDir = $PWD
  }
  return $scriptDir
}

$env:SCOOPDIR = scriptdir
. "$($env:SCOOPDIR)\..\lib\core.ps1"
. (relpath '..\lib\commands')

reset_aliases

$commands = commands

if (@($null, '-h', '--help', '/?') -contains $cmd) { exec 'help' $args }
elseif ($commands -contains $cmd) { exec $cmd $args }
else { "scoop: '$cmd' isn't a scoop command. See 'scoop help'"; exit 1 }