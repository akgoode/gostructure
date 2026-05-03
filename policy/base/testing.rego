package main

import rego.v1

test_files contains name if {
	some file in input.files
	name := file.name
	endswith(name, "_test.go")
}

skip_tests_files contains name if {
	some file in input.files
	"skip-tests" in _file_tags(file)
	name := file.name
}

deny contains msg if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	file.name != "doc.go"
	file.name != "main.go"
	expected := concat("", [trim_suffix(file.name, ".go"), "_test.go"])
	not expected in test_files
	msg := sprintf("%s — no matching test file (expected %s)", [file.name, expected])
}

test_funcs contains name if {
	some file in input.files
	file.is_test
	some f in file.funcs
	startswith(f.name, "Test")
	name := f.name
}

deny contains msg if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name != "main"
	expected := concat("", ["Test", f.name])
	not expected in test_funcs
	msg := sprintf("%s:%d — exported func '%s' has no test (expected %s)", [file.name, f.line, f.name, expected])
}

deny contains msg if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	some f in file.funcs
	f.exported
	f.receiver != ""
	expected := concat("", ["Test", f.receiver, "_", f.name])
	not expected in test_funcs
	msg := sprintf("%s:%d — exported method %s.%s has no test (expected %s)", [file.name, f.line, f.receiver, f.name, expected])
}

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
