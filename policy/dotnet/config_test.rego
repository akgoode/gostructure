package config_test

import rego.v1
import data.config

_ns(types) := {"namespaces": [{"namespace": "TestLib", "types": types}]}

test_violation_missing_options if {
	result := config.violation_missing_options with input as _ns([
		{
			"name": "OrderService",
			"kind": "class",
			"is_public": true,
			"is_abstract": false,
			"is_sealed": true,
			"is_static": false,
			"base_type": null,
			"interfaces": ["IOrderService"],
			"attributes": [],
			"constructors": [{"is_public": true, "parameters": [{"name": "repo", "type": "IOrderRepository"}]}],
			"methods": [],
			"properties": [],
			"fields": [],
		},
	])
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-CFG-001"
}

test_no_violation_when_options_exist if {
	result := config.violation_missing_options with input as _ns([
		{
			"name": "OrderService",
			"kind": "class",
			"is_public": true,
			"is_abstract": false,
			"is_sealed": true,
			"is_static": false,
			"base_type": null,
			"interfaces": ["IOrderService"],
			"attributes": [],
			"constructors": [{"is_public": true, "parameters": [{"name": "repo", "type": "IOrderRepository"}]}],
			"methods": [],
			"properties": [],
			"fields": [],
		},
		{
			"name": "OrderServiceOptions",
			"kind": "class",
			"is_public": true,
			"is_abstract": false,
			"is_sealed": false,
			"is_static": false,
			"base_type": null,
			"interfaces": [],
			"attributes": [],
			"constructors": [{"is_public": true, "parameters": []}],
			"methods": [],
			"properties": [],
			"fields": [],
		},
	])
	count(result) == 0
}

test_violation_concrete_dependency if {
	result := config.violation_concrete_dependency with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{"is_public": true, "parameters": [
			{"name": "repo", "type": "OrderRepository"},
		]}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-CFG-002"
}

test_allow_interface_dependency if {
	result := config.violation_concrete_dependency with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{"is_public": true, "parameters": [
			{"name": "repo", "type": "IOrderRepository"},
		]}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}

test_allow_ilogger_dependency if {
	result := config.violation_concrete_dependency with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{"is_public": true, "parameters": [
			{"name": "logger", "type": "ILogger<OrderService>"},
		]}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}

test_allow_options_dependency if {
	result := config.violation_concrete_dependency with input as _ns([{
		"name": "OrderService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{"is_public": true, "parameters": [
			{"name": "options", "type": "OrderServiceOptions"},
		]}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}

test_allow_primitive_params if {
	result := config.violation_concrete_dependency with input as _ns([{
		"name": "SimpleService",
		"kind": "class",
		"is_public": true,
		"is_abstract": false,
		"is_sealed": true,
		"is_static": false,
		"base_type": null,
		"interfaces": [],
		"attributes": [],
		"constructors": [{"is_public": true, "parameters": [
			{"name": "connectionString", "type": "string"},
			{"name": "timeout", "type": "TimeSpan"},
		]}],
		"methods": [],
		"properties": [],
		"fields": [],
	}])
	count(result) == 0
}
