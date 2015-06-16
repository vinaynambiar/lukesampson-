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
  json_string ($json | jq 'type')
}

function json_array($json) {
  $arr = [system.collections.arraylist]@()
  $count = $json | jq length

  for($i=0; $i -lt $count; $i++) {
    $val = json_to_hashtable ($json | jq ".[$i]")
    $null = $arr.add($val)
  }
  $arr
}

$script:escape_codes = @{
  "\0" = "`0";
  "\a" = "`a";
  "\b" = "`b";
  "\f" = "`f";
  "\n" = "`n"; 
  "\r" = "`r";
  "\t" = "`t";
  "\v" = "`v";
  '\"' = '"'
}
$script:powershell_escape = "``"
$script:json_escape = "\"
function json_string($json) {
  if ($json -eq $null) { return "" }

  $result = $json.substring(1, $json.length - 2)
  foreach($key in $escape_codes.keys) {
    $result = $result.replace($key, $escape_codes.$key)
  }

  $result
}

function json_to_hashtable($json) {
  $obj_type = json_type $json
  switch ($obj_type) {
    "object" {
      $keys = json_keys($json)
      $result = @{}

      if ($keys) {
        foreach ($key in $keys) {
          # get the type of the value
          $val = json_get $key $json
          $result.$key = json_to_hashtable $val
        }
      }
    }
    "array" {
      $result = json_array $json
    }
    "string" {
      $result = json_string $json
    }
    default {
      $result = $json
    }
  }

  $result
}

function json($json) {
  json_to_hashtable ($json | out-string)
}

function parse_json($path) {
  json (gc $path)
}
