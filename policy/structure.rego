package main

import rego.v1

deny contains msg if {
	some file in input.files
	not file.is_test
	some v in file.vars
	v.name != "_"
	msg := sprintf("%s:%d — package-level var '%s': avoid mutable global state", [file.name, v.line, v.name])
}

deny contains msg if {
	some file in input.files
	some t in file.types
	t.kind == "interface"
	count(t.methods) > 3
	msg := sprintf("%s:%d — interface '%s' has %d methods (max 3)", [file.name, t.line, t.name, count(t.methods)])
}
