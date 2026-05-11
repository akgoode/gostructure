package packages

import rego.v1

layer_names := {
	"handler", "handlers",
	"service", "services",
	"repository", "repositories",
	"store", "stores",
	"controller", "controllers",
	"model", "models",
	"util", "utils",
	"helper", "helpers",
	"common",
}

# METADATA
# title: Layer-named package
# description: >-
#   Packages named after technical layers (handlers, services, repositories, utils)
#   group code by architectural role instead of by domain. This creates grab-bag
#   packages that grow unbounded. Name packages after what they do — orders, auth,
#   billing — so a reader can find the right package by guessing its name.
#   Layering happens inside domain packages via file names (handler.go, service.go,
#   repository.go, models.go), not via top-level package names.
violation_layer_name contains obj if {
	some pkg in input.packages
	pkg.package in layer_names
	_is_top_level_internal(pkg)
	obj := {
		"msg": sprintf("%s — package '%s' named after a technical layer. Name it after what it does.", [pkg.path, pkg.package]),
		"rule_id": "GO-PKG-001",
		"severity": "error",
		"_loc": {"file": pkg.path},
	}
}

# METADATA
# title: Package has no exported functions
# description: >-
#   Every package must export at least one function. A package with no public API
#   is dead code or misplaced internal logic that should be merged into its caller.
violation_no_exports contains obj if {
	some pkg in input.packages
	pkg.package != "main"
	not _has_exported_func(pkg)
	obj := {
		"msg": sprintf("%s — package '%s' has no exported funcs", [pkg.path, pkg.package]),
		"rule_id": "GO-PKG-002",
		"severity": "error",
		"_loc": {"file": pkg.path},
	}
}

# METADATA
# title: Too many packages in module
# description: >-
#   Modules with more than 10 packages may have over-decomposed. Consider whether
#   some packages are thin wrappers that should be consolidated with their callers.
warn contains msg if {
	count(input.packages) > 10
	msg := sprintf("CONSIDER: module has %d packages (max 10). Consider consolidating.", [count(input.packages)])
}

_has_exported_func(pkg) if {
	some file in pkg.files
	some f in file.funcs
	f.exported
}

# True when a package sits directly under an internal/ directory —
# i.e. the second-to-last path segment is "internal".
_is_top_level_internal(pkg) if {
	segments := split(pkg.path, "/")
	count(segments) >= 2
	segments[count(segments) - 2] == "internal"
}
