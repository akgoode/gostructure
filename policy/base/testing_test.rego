package testing_test

import rego.v1
import data.testing

test_violation_missing_test_file if {
	result := testing.violation_missing_test_file with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-TEST-001"
	contains(obj.msg, "server_test.go")
}

test_allow_when_test_file_exists if {
	result := testing.violation_missing_test_file with input as {"files": [
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
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 0
}

test_skip_doc_go if {
	result := testing.violation_missing_test_file with input as {"files": [{
		"name": "doc.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_skip_main_go if {
	result := testing.violation_missing_test_file with input as {"files": [{
		"name": "main.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_skip_tests_tag_exempts if {
	result := testing.violation_missing_test_file with input as {"files": [{
		"name": "types.go",
		"is_test": false,
		"tags": ["skip-tests"],
		"imports": [],
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_violation_untested_func if {
	result := testing.violation_untested_func with input as {"files": [
		{
			"name": "server.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "Run", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-TEST-002"
	contains(obj.msg, "TestRun")
}

test_allow_tested_func if {
	result := testing.violation_untested_func with input as {"files": [
		{
			"name": "server.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "Run", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "TestRun", "receiver": "", "exported": true, "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 0
}

test_violation_untested_method if {
	result := testing.violation_untested_method with input as {"files": [
		{
			"name": "server.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "Start", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 15}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-TEST-003"
	contains(obj.msg, "TestServer_Start")
}

test_allow_tested_method if {
	result := testing.violation_untested_method with input as {"files": [
		{
			"name": "server.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "Start", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 15}],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "server_test.go",
			"is_test": true,
			"tags": [],
			"imports": [],
			"funcs": [{"name": "TestServer_Start", "receiver": "", "exported": true, "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
		},
	]}
	count(result) == 0
}

test_skip_main_func if {
	result := testing.violation_untested_func with input as {"files": [{
		"name": "main.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "main", "receiver": "", "exported": false, "params": [], "returns": [], "line": 5}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}
