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
        $jobs = new-object system.collections.arraylist
        foreach ($key in $keys) {
          $job = start-job -argumentlist @($json, $key) -scriptblock {
            param($json, $key)
            . "${env:SCOOPDIR}\..\lib\core.ps1"
            . "${env:SCOOPDIR}\..\lib\json.ps1"
            set-alias jq "jq-1.4"

            # get the type of the value
            $val = json_get $key $json
            $key, (json_to_hashtable $val)
          }
          $null = $jobs.add($job)
        } 

        foreach ($job in $jobs) {
          $null = wait-job $job
          $key, $val = receive-job $job
          $result.$key = $val
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

function load_codetitans {
  add-type -path "$(libdir "codetitans-json")\codetitans.json.dll"
}

function json($obj) {
  load_codetitans
  $writer = new-object codetitans.json.jsonwriter
  $writer.write($obj)
  $writer.tostring()
}

function parse_json($path) {
  $json = gc $path | out-string
  try {
    write-debug "trying codetitans"
    load_codetitans
    $reader = new-object codetitans.json.jsonreader
    $reader.read($json)
  }
  catch {
    write-debug "reverting to jq"
    json_to_hashtable $json
  }
}
