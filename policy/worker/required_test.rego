package worker_test

import rego.v1
import data.worker

_complete_worker := {"files": [
	{
		"name": "worker.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [
			{"name": "New", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10},
			{"name": "RunOnce", "receiver": "Worker", "exported": true, "params": [], "returns": [], "line": 20},
		],
		"types": [],
		"vars": [],
		"consts": [],
	},
]}

_empty_package := {"files": [{
	"name": "worker.go",
	"is_test": false,
	"tags": [],
	"imports": [],
	"funcs": [],
	"types": [],
	"vars": [],
	"consts": [],
}]}

test_no_violations_for_complete_worker if {
	r1 := worker.violation_missing_constructor with input as _complete_worker
	r2 := worker.violation_missing_runonce with input as _complete_worker
	count(r1) == 0
	count(r2) == 0
}

test_violation_missing_constructor if {
	result := worker.violation_missing_constructor with input as _empty_package
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-WORK-001"
}

test_violation_missing_runonce if {
	result := worker.violation_missing_runonce with input as _empty_package
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-WORK-002"
}

test_newworker_satisfies_constructor if {
	result := worker.violation_missing_constructor with input as {"files": [{
		"name": "worker.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "NewWorker", "receiver": "", "exported": true, "params": [], "returns": [], "line": 10}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_skip_funcs_in_test_files if {
	result := worker.violation_missing_constructor with input as {"files": [
		{
			"name": "worker.go",
			"is_test": false,
			"tags": [],
			"imports": [],
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
		},
		{
			"name": "worker_test.go",
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
