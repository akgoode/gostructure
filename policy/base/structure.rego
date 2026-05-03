package main

import rego.v1

deny contains msg if {
	some file in input.files
	not file.is_test
	not "allow-globals" in _file_tags(file)
	some v in file.vars
	v.name != "_"
	not startswith(v.name, "Err")
	msg := sprintf("%s:%d — package-level var '%s': avoid mutable global state", [file.name, v.line, v.name])
}

warn contains msg if {
	some file in input.files
	some t in file.types
	t.kind == "interface"
	count(t.methods) > 3
	msg := sprintf("%s:%d — interface '%s' has %d methods (max 3)", [file.name, t.line, t.name, count(t.methods)])
}

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
