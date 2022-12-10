deno.json: deno.yaml
	ruby -rjson -ryaml -e 'print YAML.load(STDIN.read).to_json' < deno.yaml | jq -S . > deno.json
