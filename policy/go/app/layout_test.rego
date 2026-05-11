package layout_test

import rego.v1
import data.layout

# --- Packages outside expected top-level dirs ---

_empty_pkg(name, path) := {
	"package": name,
	"path": path,
	"files": [{"name": sprintf("%s.go", [name]), "is_test": false, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []}],
}

test_warn_package_outside_expected_dirs if {
	result := layout.warn with input as {"packages": [_empty_pkg("mylib", "pkg/mylib")]}
	some msg in result
	contains(msg, "outside cmd/, api/, and internal/")
}

test_warn_root_level_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("utils", "./utils")]}
	some msg in result
	contains(msg, "outside cmd/, api/, and internal/")
}

test_no_warn_internal_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("orders", "internal/orders")]}
	not _any_contains(result, "outside cmd/")
}

test_no_warn_cmd_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("main", "cmd/api")]}
	not _any_contains(result, "outside cmd/")
}

test_no_warn_api_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("proto", "api/v1")]}
	not _any_contains(result, "outside cmd/")
}

test_no_warn_gen_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("v1", "gen/go/echo/v1")]}
	not _any_contains(result, "outside cmd/")
}

test_no_warn_client_package if {
	result := layout.warn with input as {"packages": [_empty_pkg("client", "./client")]}
	not _any_contains(result, "outside cmd/")
}

test_no_warn_absolute_internal_path if {
	result := layout.warn with input as {"packages": [_empty_pkg("orders", "/abs/path/project/internal/orders")]}
	not _any_contains(result, "outside cmd/")
}

# --- shared/ file count ---

test_warn_shared_too_many_files if {
	files := [f | some i in numbers.range(1, 7); f := {
		"name": sprintf("file%d.go", [i]),
		"is_test": false,
		"funcs": [],
		"types": [],
		"vars": [],
		"consts": [],
		"imports": [],
	}]
	result := layout.warn with input as {"packages": [{
		"package": "shared",
		"path": "internal/shared",
		"files": files,
	}]}
	count(result) > 0
}

test_no_warn_shared_small if {
	result := layout.warn with input as {"packages": [{
		"package": "shared",
		"path": "internal/shared",
		"files": [
			{"name": "middleware.go", "is_test": false, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []},
			{"name": "errors.go", "is_test": false, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []},
			{"name": "middleware_test.go", "is_test": true, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []},
		],
	}]}
	count(result) == 0
}

test_no_warn_shared_test_files_excluded if {
	files := array.concat(
		[f | some i in numbers.range(1, 6); f := {
			"name": sprintf("file%d.go", [i]),
			"is_test": false,
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
		[f | some i in numbers.range(1, 6); f := {
			"name": sprintf("file%d_test.go", [i]),
			"is_test": true,
			"funcs": [],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	)
	result := layout.warn with input as {"packages": [{
		"package": "shared",
		"path": "internal/shared",
		"files": files,
	}]}
	count(result) == 0
}

# --- Domain package expected files ---

_domain_pkg_with_constructor := {
	"package": "orders",
	"path": "internal/orders",
	"files": [
		{
			"name": "handler.go",
			"is_test": false,
			"funcs": [{"name": "NewHandler", "exported": true, "receiver": "", "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		},
	],
}

test_warn_domain_missing_service if {
	result := layout.warn with input as {"packages": [_domain_pkg_with_constructor]}
	some msg in result
	contains(msg, "service.go")
}

test_warn_domain_missing_models if {
	result := layout.warn with input as {"packages": [_domain_pkg_with_constructor]}
	some msg in result
	contains(msg, "models.go")
}

test_no_warn_domain_complete if {
	pkg := {
		"package": "orders",
		"path": "internal/orders",
		"files": [
			{
				"name": "handler.go",
				"is_test": false,
				"funcs": [{"name": "NewHandler", "exported": true, "receiver": "", "params": [], "returns": [], "line": 5}],
				"types": [],
				"vars": [],
				"consts": [],
				"imports": [],
			},
			{"name": "service.go", "is_test": false, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []},
			{"name": "models.go", "is_test": false, "funcs": [], "types": [], "vars": [], "consts": [], "imports": []},
		],
	}
	result := layout.warn with input as {"packages": [pkg]}
	not _any_contains(result, "missing")
}

test_no_warn_shared_package_missing_files if {
	pkg := {
		"package": "shared",
		"path": "internal/shared",
		"files": [{
			"name": "middleware.go",
			"is_test": false,
			"funcs": [{"name": "New", "exported": true, "receiver": "", "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	}
	result := layout.warn with input as {"packages": [pkg]}
	not _any_contains(result, "domain package missing")
}

test_no_warn_no_constructor if {
	pkg := {
		"package": "types",
		"path": "internal/types",
		"files": [{
			"name": "types.go",
			"is_test": false,
			"funcs": [],
			"types": [{"name": "Order", "kind": "struct", "exported": true, "line": 3}],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	}
	result := layout.warn with input as {"packages": [pkg]}
	not _any_contains(result, "domain package missing")
}

test_no_warn_nested_subdomain_package if {
	pkg := {
		"package": "repository",
		"path": "internal/product/repository",
		"files": [{
			"name": "repo.go",
			"is_test": false,
			"funcs": [{"name": "New", "exported": true, "receiver": "", "params": [], "returns": [], "line": 5}],
			"types": [],
			"vars": [],
			"consts": [],
			"imports": [],
		}],
	}
	result := layout.warn with input as {"packages": [pkg]}
	not _any_contains(result, "domain package missing")
}

_any_contains(set, substr) if {
	some s in set
	contains(s, substr)
}
