package namespaces_test

import rego.v1
import data.namespaces

test_violation_layer_named_namespace if {
	result := namespaces.violation_layer_name with input as {"namespaces": [
		{"namespace": "MyApp.Services", "types": []},
	]}
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-NS-001"
}

test_no_violation_domain_namespace if {
	result := namespaces.violation_layer_name with input as {"namespaces": [
		{"namespace": "MyApp.Orders", "types": []},
	]}
	count(result) == 0
}

test_violation_helpers_namespace if {
	result := namespaces.violation_layer_name with input as {"namespaces": [
		{"namespace": "MyApp.Helpers", "types": []},
	]}
	count(result) == 1
}

test_violation_no_public_types if {
	result := namespaces.violation_no_public_types with input as {"namespaces": [{
		"namespace": "MyApp.Internal",
		"types": [{
			"name": "InternalHelper",
			"kind": "class",
			"is_public": false,
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
		}],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "NET-NS-002"
}

test_no_violation_has_public_type if {
	result := namespaces.violation_no_public_types with input as {"namespaces": [{
		"namespace": "MyApp.Orders",
		"types": [{
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
		}],
	}]}
	count(result) == 0
}

test_warn_too_many_namespaces if {
	nss := [ns | some i in numbers.range(1, 16); ns := {
		"namespace": sprintf("MyApp.Ns%d", [i]),
		"types": [{"name": "T", "kind": "class", "is_public": true, "is_abstract": false, "is_sealed": true, "is_static": false, "base_type": null, "interfaces": [], "attributes": [], "constructors": [], "methods": [], "properties": [], "fields": []}],
	}]
	result := namespaces.warn with input as {"namespaces": nss}
	count(result) > 0
}
