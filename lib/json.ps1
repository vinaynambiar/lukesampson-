function json_get($name, $json) {
  write-debug "getting $name"
  $val = $json | jq ".\`"$name\`""
  if ($val -eq "null") { return $null }

  $val
}

function json_set($name, $val, $json) {
  if (!$json) { $json = "{}" }

  if($val -eq $null) {
    $json = $json | jq "del(.$name)"
  }
  else {
    $json = $json | jq ". += {${name}: \`"$val\`"}"
  }

  $json
}

function json_keys($json) {
  $json_keys = $json | jq 'keys'
  json_array $json_keys
}

function json_type($json) {
  iex ($json | jq 'type')
}

function json_array($json) {
  $json_arr = $json | jq 'reduce .[] as $item (\"\"; . + $item + \" \")'
  $arr = (iex $json_arr).trim().split(' ')
  $arr
}

function json_to_hashtable($json) {
  $keys = json_keys($json)

  $result = @{}
  foreach ($key in $keys) {
    # get the type of the value
    $val = json_get $key $json
    $type = json_type $val

    # if it's an object
    # recurse
    if ($type -eq "object") {
      $result.$key = json_to_hashtable $val
    }
    elseif ($type -eq "string") {
      $result.$key = iex $val
    }
    elseif ($type -eq "array") {
      $result.$key = json_array $val
    }
    else {
      $result.$key = $val
    }
  }

  $result
}
