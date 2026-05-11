package errors_test

import rego.v1
import data.errors

test_violation_missing_domain_errors if {
	result := errors.violation_missing_domain_errors with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "Get", "receiver": "Store", "exported": true, "params": [], "returns": [{"type": "error"}], "returns_error": true, "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-ERR-001"
}

test_allow_sentinel_errors if {
	result := errors.violation_missing_domain_errors with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "Get", "receiver": "Store", "exported": true, "params": [], "returns": [{"type": "error"}], "returns_error": true, "line": 10}],
		"types": [],
		"vars": [{"name": "ErrNotFound", "line": 5, "exported": true}],
		"consts": [],
	}]}
	count(result) == 0
}

test_allow_error_type if {
	result := errors.violation_missing_domain_errors with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "Get", "receiver": "Store", "exported": true, "params": [], "returns": [{"type": "error"}], "returns_error": true, "line": 10}],
		"types": [{"name": "ValidationError", "kind": "struct", "exported": true, "line": 5, "fields": [], "methods": []}],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_no_violation_when_no_error_returns if {
	result := errors.violation_missing_domain_errors with input as {"files": [{
		"name": "types.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "Format", "receiver": "", "exported": true, "params": [], "returns": [{"type": "string"}], "returns_error": false, "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_skip_unexported_funcs if {
	result := errors.violation_missing_domain_errors with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "get", "receiver": "Store", "exported": false, "params": [], "returns": [{"type": "error"}], "returns_error": true, "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_error_in_test_file_doesnt_count if {
	result := errors.violation_missing_domain_errors with input as {"files": [
		{
			"name": "store.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "Get", "receiver": "Store", "exported": true, "params": [], "returns": [{"type": "error"}], "returns_error": true, "line": 10}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "store_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [],
			"types": [],
			"vars": [{"name": "ErrTest", "line": 5, "exported": true}],
			"consts": [],
		},
	]}
	count(result) == 1
}
