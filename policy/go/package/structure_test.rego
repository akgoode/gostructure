package structure_test

import rego.v1
import data.structure

test_violation_global_var if {
	result := structure.violation_global_vars with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"consts": [],
		"vars": [{"name": "db", "line": 5, "exported": false}],
	}]}
	count(result) == 1
	some obj in result
	obj.rule_id == "GO-STRUCT-001"
	obj._loc.line == 5
}

test_allow_error_sentinel_vars if {
	result := structure.violation_global_vars with input as {"files": [{
		"name": "errors.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"consts": [],
		"vars": [{"name": "ErrNotFound", "line": 7, "exported": true}],
	}]}
	count(result) == 0
}

test_allow_underscore_var if {
	result := structure.violation_global_vars with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"consts": [],
		"vars": [{"name": "_", "line": 3, "exported": false}],
	}]}
	count(result) == 0
}

test_allow_globals_tag_exempts if {
	result := structure.violation_global_vars with input as {"files": [{
		"name": "globals.go",
		"is_test": false,
		"tags": ["allow-globals"],
		"imports": [],
		"funcs": [],
		"types": [],
		"consts": [],
		"vars": [{"name": "registry", "line": 10, "exported": false}],
	}]}
	count(result) == 0
}

test_skip_test_files if {
	result := structure.violation_global_vars with input as {"files": [{
		"name": "server_test.go",
		"is_test": true,
		"tags": [],
		"imports": [],
		"funcs": [],
		"types": [],
		"consts": [],
		"vars": [{"name": "testDB", "line": 5, "exported": false}],
	}]}
	count(result) == 0
}

test_warn_large_interface if {
	result := structure.warn with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Store",
			"kind": "interface",
			"exported": true,
			"line": 5,
			"methods": [
				{"name": "Get"},
				{"name": "List"},
				{"name": "Create"},
				{"name": "Update"},
				{"name": "Delete"},
				{"name": "Archive"},
			],
			"fields": [],
		}],
	}]}
	count(result) > 0
}

test_no_warn_small_interface if {
	result := structure.warn with input as {"files": [{
		"name": "store.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Reader",
			"kind": "interface",
			"exported": true,
			"line": 5,
			"methods": [{"name": "Read"}, {"name": "Close"}],
			"fields": [],
		}],
	}]}
	count(result) == 0
}

test_warn_too_many_funcs if {
	funcs := [f | some i in numbers.range(1, 11); f := {"name": sprintf("helper%d", [i]), "receiver": "", "exported": false, "params": [], "returns": [], "line": i * 10}]
	result := structure.warn with input as {"files": [{
		"name": "big.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": funcs,
		"types": [],
		"vars": [],
		"consts": [],
	}]}
	count(result) > 0
}

test_warn_too_many_params if {
	result := structure.warn with input as {"files": [{
		"name": "execute.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"vars": [],
		"consts": [],
		"types": [],
		"funcs": [{
			"name": "Execute",
			"receiver": "",
			"exported": true,
			"line": 10,
			"params": [
				{"name": "a", "type": "string"},
				{"name": "b", "type": "string"},
				{"name": "c", "type": "string"},
				{"name": "d", "type": "string"},
				{"name": "e", "type": "string"},
			],
			"returns": [],
		}],
	}]}
	count(result) > 0
}

test_warn_too_many_returns if {
	result := structure.warn with input as {"files": [{
		"name": "process.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"vars": [],
		"consts": [],
		"types": [],
		"funcs": [{
			"name": "Process",
			"receiver": "",
			"exported": true,
			"line": 10,
			"params": [],
			"returns": [
				{"type": "string"},
				{"type": "int"},
				{"type": "error"},
			],
		}],
	}]}
	count(result) > 0
}

test_warn_large_struct if {
	fields := [f | some i in numbers.range(1, 9); f := {"name": sprintf("Field%d", [i]), "type": "string", "exported": true}]
	result := structure.warn with input as {"files": [{
		"name": "order.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Order",
			"kind": "struct",
			"exported": true,
			"line": 5,
			"fields": fields,
			"methods": [],
		}],
	}]}
	count(result) > 0
}

test_config_struct_exempt_from_field_count if {
	fields := [f | some i in numbers.range(1, 12); f := {"name": sprintf("Field%d", [i]), "type": "string", "exported": true}]
	result := structure.warn with input as {"files": [{
		"name": "config.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Config",
			"kind": "struct",
			"exported": true,
			"line": 5,
			"fields": fields,
			"methods": [],
		}],
	}]}
	count(result) == 0
}

test_warn_too_many_methods if {
	funcs := [f | some i in numbers.range(1, 11); f := {"name": sprintf("Method%d", [i]), "receiver": "Worker", "exported": true, "params": [], "returns": [], "line": i * 10}]
	result := structure.warn with input as {"files": [{
		"name": "worker.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": funcs,
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Worker",
			"kind": "struct",
			"exported": true,
			"line": 3,
			"fields": [],
			"methods": [],
		}],
	}]}
	count(result) > 0
}

test_warn_exported_struct_no_constructor if {
	# Struct with an injected dep (*sql.DB) AND behavior (Start method) —
	# without a constructor, every caller assembles it by hand. Methods are
	# the signal that this is a service, not data.
	result := structure.warn with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [{"name": "Start", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 30}],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Server",
			"kind": "struct",
			"exported": true,
			"line": 5,
			"fields": [{"name": "db", "type": "*sql.DB", "exported": false}],
			"methods": [],
		}],
	}]}
	count(result) > 0
}

test_no_warn_struct_with_constructor if {
	result := structure.warn with input as {"files": [{
		"name": "server.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [
			{"name": "NewServer", "receiver": "", "exported": true, "params": [], "returns": [], "line": 20},
			{"name": "Start", "receiver": "Server", "exported": true, "params": [], "returns": [], "line": 30},
		],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Server",
			"kind": "struct",
			"exported": true,
			"line": 5,
			"fields": [{"name": "db", "type": "*sql.DB", "exported": false}],
			"methods": [],
		}],
	}]}
	not _any_contains(result, "no constructor")
}

# Pure data types — no methods, no behavior — are exempt. Product carries
# package-qualified fields (time.Time) and a same-package value type
# (Money), but is a plain DTO. A constructor would be ceremony around a
# struct literal.
test_no_warn_data_type_with_qualified_fields if {
	result := structure.warn with input as {"files": [{
		"name": "product.go",
		"is_test": false,
		"tags": [],
		"imports": [],
		"funcs": [],
		"vars": [],
		"consts": [],
		"types": [{
			"name": "Product",
			"kind": "struct",
			"exported": true,
			"line": 5,
			"fields": [
				{"name": "ID", "type": "string", "exported": true},
				{"name": "Price", "type": "Money", "exported": true},
				{"name": "CreatedAt", "type": "time.Time", "exported": true},
			],
			"methods": [],
		}],
	}]}
	not _any_contains(result, "no constructor")
}

_any_contains(results, substr) if {
	some msg in results
	contains(msg, substr)
}
