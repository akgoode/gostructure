package imports_test

import rego.v1
import data.imports

test_violation_test_import_in_prod if {
	result := imports.violation_test_import with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": ["fmt", "github.com/stretchr/testify/assert", "net/http"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-IMP-001"
	contains(obj.msg, "testify/assert")
}

test_allow_test_import_in_test_file if {
	result := imports.violation_test_import with input as {"files": [{
		"name": "server_test.go",
		"is_test": true,
		"tags": [],
		"imports": ["github.com/stretchr/testify/assert", "testing"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_allow_normal_imports if {
	result := imports.violation_test_import with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": ["fmt", "net/http", "context"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_violation_gomock_import if {
	result := imports.violation_test_import with input as {"files": [{
		"name": "client.go",
		"is_test": false,
		"tags": [],
		"imports": ["go.uber.org/mock/gomock"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
}

test_warn_too_many_imports if {
	result := imports.warn with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": ["a", "b", "c", "d", "e", "f", "g", "h", "i"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) > 0
}

test_no_warn_reasonable_imports if {
	result := imports.warn with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": ["fmt", "net/http", "context"],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}
