package config_test

import rego.v1
import data.config

test_violation_missing_config_struct if {
	result := config.violation_missing_config with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "New", "receiver": "", "exported": true, "params": [{"name": "db", "type": "*sql.DB"}], "returns": [], "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-CFG-001"
}

test_allow_constructor_with_config if {
	result := config.violation_missing_config with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "New", "receiver": "", "exported": true, "params": [{"name": "cfg", "type": "Config"}], "returns": [], "line": 10}],
		"types": [{"name": "Config", "kind": "struct", "exported": true, "line": 5, "fields": [], "methods": []}],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_violation_disconnected_config if {
	result := config.violation_disconnected_config with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "New", "receiver": "", "exported": true, "params": [{"name": "db", "type": "*sql.DB"}], "returns": [], "line": 15}],
		"types": [{"name": "Config", "kind": "struct", "exported": true, "line": 5, "fields": [], "methods": []}],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-CFG-002"
}

test_no_violation_when_no_constructor if {
	result_cfg := config.violation_missing_config with input as {"files": [{
		"name": "types.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [{"name": "Order", "kind": "struct", "exported": true, "line": 5, "fields": [], "methods": []}],
		"vars": [],
		"consts": [],
	}]}
	result_disc := config.violation_disconnected_config with input as {"files": [{
		"name": "types.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [{"name": "Order", "kind": "struct", "exported": true, "line": 5, "fields": [], "methods": []}],
		"vars": [],
		"consts": [],
	}]}
	count(result_cfg) == 0
	count(result_disc) == 0
}

test_skip_constructors_in_test_files if {
	result := config.violation_missing_config with input as {"files": [
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "NewTestServer", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "server.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 0
}
