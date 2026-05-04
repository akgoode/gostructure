package testing

import rego.v1

_found_test_files contains name if {
	some file in input.files
	name := file.name
	endswith(name, "_test.go")
}

skip_tests_files contains name if {
	some file in input.files
	"skip-tests" in _file_tags(file)
	name := file.name
}

# METADATA
# title: Missing test file
# description: >
#   Every non-test source file (except doc.go, main.go) must have a corresponding
#   _test.go file. Respects the skip-tests file tag.
violation_missing_test_file contains obj if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	file.name != "doc.go"
	file.name != "main.go"
	expected := concat("", [trim_suffix(file.name, ".go"), "_test.go"])
	not expected in _found_test_files
	obj := {
		"msg": sprintf("%s — no matching test file (expected %s). Every source file needs a corresponding test file.", [file.name, expected]),
		"rule_id": "GO-TEST-001",
		"severity": "error",
		"_loc": {"file": file.name},
	}
}

_found_test_funcs contains name if {
	some file in input.files
	file.is_test
	some f in file.funcs
	startswith(f.name, "Test")
	name := f.name
}

# METADATA
# title: Exported function has no test
# description: >
#   Every exported top-level function must have a Test<FuncName> test.
#   Respects the skip-tests file tag.
violation_untested_func contains obj if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name != "main"
	expected := concat("", ["Test", f.name])
	not expected in _found_test_funcs
	obj := {
		"msg": sprintf("%s:%d — exported func '%s' has no test. Add %s to the test file.", [file.name, f.line, f.name, expected]),
		"rule_id": "GO-TEST-002",
		"severity": "error",
		"_loc": {"file": file.name, "line": f.line},
	}
}

# METADATA
# title: Exported method has no test
# description: >
#   Every exported method must have a Test<Receiver>_<Method> test.
#   Respects the skip-tests file tag.
violation_untested_method contains obj if {
	some file in input.files
	not file.is_test
	not file.name in skip_tests_files
	some f in file.funcs
	f.exported
	f.receiver != ""
	expected := concat("", ["Test", f.receiver, "_", f.name])
	not expected in _found_test_funcs
	obj := {
		"msg": sprintf("%s:%d — exported method %s.%s has no test. Add %s to the test file.", [file.name, f.line, f.receiver, f.name, expected]),
		"rule_id": "GO-TEST-003",
		"severity": "error",
		"_loc": {"file": file.name, "line": f.line},
	}
}

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
