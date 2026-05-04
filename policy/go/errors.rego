package errors

import rego.v1

has_error_returns if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.returns_error
}

has_domain_errors if {
	some file in input.files
	not file.is_test
	some v in file.vars
	startswith(v.name, "Err")
}

has_domain_errors if {
	some file in input.files
	not file.is_test
	some t in file.types
	endswith(t.name, "Error")
}

# METADATA
# title: Missing domain error types
# description: >-
#   Packages with exported functions that return error must define domain error
#   types — either sentinel errors (var ErrNotFound = errors.New(...)) or custom
#   error types (type ValidationError struct). Domain errors make the codebase
#   searchable, tests precise, and give callers a contract for what can go wrong.
violation_missing_domain_errors contains obj if {
	has_error_returns
	not has_domain_errors
	obj := {
		"msg": "exported funcs return error but no domain errors defined. Add var Err* or type *Error.",
		"rule_id": "GO-ERR-001",
		"severity": "error",
	}
}
