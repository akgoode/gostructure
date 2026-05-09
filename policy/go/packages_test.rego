package packages_test

import rego.v1
import data.packages

test_violation_no_exported_funcs if {
	result := packages.violation_no_exports with input as {"packages": [{
		"package": "internal",
		"path": "internal/secret",
		"files": [{
			"name": "hidden.go",
			"is_test": false,
			"funcs": [{"name": "helper", "exported": false, "receiver": "", "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-PKG-002"
}

test_allow_package_with_exports if {
	result := packages.violation_no_exports with input as {"packages": [{
		"package": "orders",
		"path": "internal/orders",
		"files": [{
			"name": "orders.go",
			"is_test": false,
			"funcs": [{"name": "New", "exported": true, "receiver": "", "params": [], "returns": [], "line": 10}],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	}]}
	count(result) == 0
}

test_warn_too_many_packages if {
	pkgs := [p | some i in numbers.range(1, 11); p := {"package": sprintf("pkg%d", [i]), "path": sprintf("internal/pkg%d", [i]), "files": []}]
	result := packages.warn with input as {"packages": pkgs}
	count(result) > 0
}

test_no_warn_reasonable_package_count if {
	result := packages.warn with input as {"packages": [
		{"package": "orders", "path": "internal/orders", "files": []},
		{"package": "auth", "path": "internal/auth", "files": []},
	]}
	count(result) == 0
}
