package structure_test

import rego.v1
import data.structure

_ns(types) := {"namespaces": [{"namespace": "TestLib", "types": types}]}

test_violation_mutable_static if {
	result := structure.violation_mutable_static with input as _ns([{
		"name": "Constants",
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
		"fields": [{"name": "Counter", "type": "int", "is_public": true, "is_static": true, "is_readonly": false}],
	}])
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-STRUCT-001"
}

test_allow_readonly_static if {
	result := structure.violation_mutable_static with input as _ns([{
		"name": "Constants",
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
		"fields": [{"name": "Timeout", "type": "TimeSpan", "is_public": true, "is_static": true, "is_readonly": true}],
	}])
	count(result) == 0
}

test_allow_private_static if {
	result := structure.violation_mutable_static with input as _ns([{
		"name": "Service",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [],
		"properties": [],
		"fields": [{"name": "_counter", "type": "int", "is_public": false, "is_static": true, "is_readonly": false}],
	}])
	count(result) == 0
}

test_warn_large_interface if {
	methods := [m | some i in numbers.range(1, 6); m := {
		"name": sprintf("Method%d", [i]),
		"is_public": true,
		"is_static": false,
		"is_virtual": true,
		"is_override": false,
		"parameters": [],
		"return_type": "void",
		"attributes": [],
	}]
	result := structure.warn with input as _ns([{
		"name": "IBigService",
		"kind": "interface",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": false,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": methods,
		"properties": [],
		"fields": [],
	}])
	count(result) > 0
}

test_no_warn_small_interface if {
	result := structure.warn with input as _ns([{
		"name": "IReader",
		"kind": "interface",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": false,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [{
			"name": "Read",
			"is_public": true,
			"is_static": false,
			"is_virtual": true,
			"is_override": false,
			"parameters": [],
			"return_type": "string",
			"attributes": [],
		}],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}

test_warn_too_many_method_params if {
	result := structure.warn with input as _ns([{
		"name": "Service",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [{
			"name": "Execute",
			"is_public": true,
			"is_static": false,
			"is_virtual": false,
			"is_override": false,
			"parameters": [
				{"name": "a", "type": "string"},
				{"name": "b", "type": "string"},
				{"name": "c", "type": "string"},
				{"name": "d", "type": "string"},
				{"name": "e", "type": "string"},
			],
			"return_type": "void",
			"attributes": [],
		}],
		"properties": [],
		"fields": [],
	}])
	count(result) > 0
}

test_warn_too_many_ctor_params if {
	result := structure.warn with input as _ns([{
		"name": "BigService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{
			"is_public": true,
			"parameters": [
				{"name": "a", "type": "IA"},
				{"name": "b", "type": "IB"},
				{"name": "c", "type": "IC"},
				{"name": "d", "type": "ID"},
				{"name": "e", "type": "IE"},
				{"name": "f", "type": "IF"},
				{"name": "g", "type": "IG"},
			],
		}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) > 0
}

test_warn_unsealed_class if {
	result := structure.warn with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": false,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) > 0
}

test_no_warn_sealed_class if {
	result := structure.warn with input as _ns([{
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
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}

test_exception_exempt_from_sealed if {
	result := structure.warn with input as _ns([{
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
	}])
	count(result) == 0
}

test_options_exempt_from_sealed if {
	result := structure.warn with input as _ns([{
		"name": "OrderServiceOptions",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": false,
		"is_static": false,
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
