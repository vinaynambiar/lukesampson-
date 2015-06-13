function get_json_field($name, $json) {
  $val = $json | jq ".$name"
  if ($val -eq "null") { $val = $null }
  if ($val -is [system.string] -and $val.startswith('"')) {
    $val = $val.substring(1, $val.length - 2)
  }
  $val
}