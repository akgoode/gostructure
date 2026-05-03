package main

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

deny contains msg if {
	has_error_returns
	not has_domain_errors
	msg := "package has exported funcs that return error but no domain error types (Err* vars or *Error types)"
}
