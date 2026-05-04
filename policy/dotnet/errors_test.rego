package errors_test

import rego.v1
import data.errors

_ns(types) := {"namespaces": [{"namespace": "TestLib.Orders", "types": types}]}

test_violation_no_exceptions if {
	result := errors.violation_missing_exceptions with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [{"name": "CreateOrder", "is_public": true, "is_static": false, "is_virtual": false, "is_override": false, "parameters": [], "return_type": "void", "attributes": []}],
		"properties": [],
		"fields": [],
	}])
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-ERR-001"
}

test_no_violation_with_exception if {
	result := errors.violation_missing_exceptions with input as _ns([
		{
			"name": "OrderService",
			"kind": "class",
			"is_public": true,
			"is_abstract": false,
			"is_sealed": true,
			"is_static": false,
			"base_type": null,
			"interfaces": [],
			"attributes": [],
			"constructors": [],
			"methods": [{"name": "CreateOrder", "is_public": true, "is_static": false, "is_virtual": false, "is_override": false, "parameters": [], "return_type": "void", "attributes": []}],
			"properties": [],
			"fields": [],
		},
		{
			"name": "OrderNotFoundException",
			"kind": "class",
			"is_public": true,
			"is_abstract": false,
			"is_sealed": false,
			"is_static": false,
			"base_type": "Exception",
			"interfaces": [],
			"attributes": [],
			"constructors": [],
			"methods": [],
			"properties": [],
			"fields": [],
		},
	])
	count(result) == 0
}

test_no_violation_static_only if {
	result := errors.violation_missing_exceptions with input as _ns([{
		"name": "OrderConstants",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": false,
		"is_static": true,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}
