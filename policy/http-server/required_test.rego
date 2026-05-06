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

# GO-HTTP-004: top-level handler functions are forbidden — handlers must be
# methods on *Server or closures returned by factory functions.

test_violation_top_level_handler_fires if {
	# Package-scope func with the canonical (w, r) handler signature — the
	# pattern this rule is designed to catch.
	result := httpserver.violation_top_level_handler with input as {"files": [{
		"name": "handlers.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{
			"name": "HandleProducts",
			"receiver": "",
			"exported": true,
			"params": [
				{"name": "w", "type": "http.ResponseWriter"},
				{"name": "r", "type": "*http.Request"},
			],
			"returns": [],
			"line": 12,
		}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-HTTP-004"
	contains(obj.msg, "HandleProducts")
}

test_handler_method_on_server_passes if {
	# Method on *Server — the preferred pattern.
	result := httpserver.violation_top_level_handler with input as {"files": [{
		"name": "products.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{
			"name": "handleProducts",
			"receiver": "Server",
			"exported": false,
			"params": [
				{"name": "w", "type": "http.ResponseWriter"},
				{"name": "r", "type": "*http.Request"},
			],
			"returns": [],
			"line": 12,
		}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_closure_factory_passes if {
	# Factory func that takes deps and returns http.HandlerFunc — has no (w, r)
	# in its own signature, so the rule does not fire on it.
	result := httpserver.violation_top_level_handler with input as {"files": [{
		"name": "products.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{
			"name": "createProduct",
			"receiver": "",
			"exported": false,
			"params": [{"name": "store", "type": "*Store"}],
			"returns": ["http.HandlerFunc"],
			"line": 12,
		}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

test_unexported_top_level_handler_also_fires if {
	# Even unexported package-scope handlers are smelly — same dep-injection
	# problem. The rule fires on all package-scope handlers, not just exported.
	result := httpserver.violation_top_level_handler with input as {"files": [{
		"name": "handlers.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{
			"name": "handleProducts",
			"receiver": "",
			"exported": false,
			"params": [
				{"name": "w", "type": "http.ResponseWriter"},
				{"name": "r", "type": "*http.Request"},
			],
			"returns": [],
			"line": 12,
		}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 1
}

test_test_file_handlers_skipped if {
	# Handlers inside _test.go files are part of test fixtures (httptest mocks,
	# stub servers); the rule should skip them.
	result := httpserver.violation_top_level_handler with input as {"files": [{
		"name": "server_test.go",
		"is_test": true,
		"tags": [],
		"imports": [],
		"funcs": [{
			"name": "stubHandler",
			"receiver": "",
			"exported": false,
			"params": [
				{"name": "w", "type": "http.ResponseWriter"},
				{"name": "r", "type": "*http.Request"},
			],
			"returns": [],
			"line": 5,
		}],
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) == 0
}

# GO-HTTP-005: Health() must return a struct type defined in the package.

# Helper: build an input with a Health method whose returns array we control,
# plus a HealthStatus struct so the package has a candidate to match against.
_pkg_with_health(returns) := {"files": [{
	"name": "health.go",
	"is_test": false,
	"tags": [],
	"imports": [],
	"funcs": [{
		"name": "Health",
		"receiver": "Server",
		"exported": true,
		"params": [],
		"returns": returns,
		"line": 12,
	}],
	"types": [{
		"name": "HealthStatus",
		"kind": "struct",
		"exported": true,
		"line": 5,
		"fields": [],
		"methods": [],
	}],
	"vars": [],
	"consts": [],
}]}

test_health_returns_struct_passes if {
	# Health() HealthStatus — the canonical shape.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["HealthStatus"])
	count(result) == 0
}

test_health_returns_pointer_to_struct_passes if {
	# Health() *HealthStatus — pointer to a local struct still counts.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["*HealthStatus"])
	count(result) == 0
}

test_health_multireturn_passes if {
	# Health() (HealthStatus, error) — multiple returns; one is the struct.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["HealthStatus", "error"])
	count(result) == 0
}

test_health_returns_string_fires if {
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["string"])
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-HTTP-005"
}

test_health_returns_map_fires if {
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["map[string]string"])
	count(result) == 1
}

test_health_returns_error_only_fires if {
	# Returning only error is not a contract callers can program against.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["error"])
	count(result) == 1
}

test_health_returns_external_type_fires if {
	# A struct defined in another package isn't in this package's types
	# inventory, so the rule fires. The intent: HTTP server packages own
	# their health-shape contract.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health(["other.Status"])
	count(result) == 1
}

test_health_no_return_fires if {
	# Health() with no return at all — useless to callers.
	result := httpserver.violation_health_invalid_return with input as _pkg_with_health([])
	count(result) == 1
}

test_health_missing_does_not_fire if {
	# When Health doesn't exist at all, GO-HTTP-003 handles that. GO-HTTP-005
	# must stay silent so we don't double-report.
	result := httpserver.violation_health_invalid_return with input as {"files": [{
		"name": "server.go",
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
