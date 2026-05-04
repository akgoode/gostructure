package httpserver_test

import rego.v1
import data.httpserver

_complete_server := {"files": [
	{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [
			{"name": "New", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10},
			{"name": "Routes", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 20},
			{"name": "Health", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 30},
		],
		"types": [],
		"vars": [],
		"consts": [],
	},
]}

_empty_package := {"files": [{
	"name": "server.go",
	"is_test": false,
	"tags": [],
	"imports": [],
	"funcs": [],
	"types": [],
	"vars": [],
	"consts": [],
}]}

test_no_violations_for_complete_server if {
	r1 := httpserver.violation_missing_constructor with input as _complete_server
	r2 := httpserver.violation_missing_routes with input as _complete_server
	r3 := httpserver.violation_missing_health with input as _complete_server
	count(r1) == 0
	count(r2) == 0
	count(r3) == 0
}

test_violation_missing_constructor if {
	result := httpserver.violation_missing_constructor with input as _empty_package
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-HTTP-001"
}

test_violation_missing_routes if {
	result := httpserver.violation_missing_routes with input as _empty_package
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-HTTP-002"
}

test_violation_missing_health if {
	result := httpserver.violation_missing_health with input as _empty_package
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-HTTP-003"
}

test_newserver_satisfies_constructor if {
	result := httpserver.violation_missing_constructor with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "NewServer", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_skip_funcs_in_test_files if {
	result := httpserver.violation_missing_constructor with input as {"files": [
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
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "New", "receiver": "", "exported": true, "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 1
}
