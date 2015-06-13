function get_json_field($name, $json) {
  $val = $json | jq ".$name"
  if ($val -eq "null") { $val = $null }
  if ($val -is [system.string] -and $val.startswith('"')) {
    $val = $val.substring(1, $val.length - 2)
  }
  $val
}

function set_json_field($name, $val, $json) {
  if (!$json) { $json = "{}" }

  if($val -eq $null) {
    #$json = $json | jq "del(.$name)"
  }
  else {
    $json = $json | jq ". += {${name}: \`"$val\`"}"
  }

  $json
}