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
# description: >
#   Packages named after technical layers (handlers, services, repositories) group
#   by role instead of by domain. Name packages after what they do.
violation_layer_name contains obj if {
	some pkg in input.packages
	pkg.package in layer_names
	obj := {
		"msg": sprintf("%s — package named after a technical layer; name packages after what they do, not what architectural role they play", [pkg.path]),
		"rule_id": "GO-PKG-001",
		"severity": "error",
		"_loc": {"file": pkg.path},
	}
}

# METADATA
# title: Package has no exported functions
# description: >
#   Every package must export at least one function. A package with no public API
#   is dead code or misplaced internal logic.
violation_no_exports contains obj if {
	some pkg in input.packages
	not _has_exported_func(pkg)
	obj := {
		"msg": sprintf("%s — package '%s' has no exported funcs; every package should provide at least one", [pkg.path, pkg.package]),
		"rule_id": "GO-PKG-002",
		"severity": "error",
		"_loc": {"file": pkg.path},
	}
}

# METADATA
# title: Too many packages in module
# description: >
#   Modules with more than 10 packages may benefit from consolidation.
warn contains msg if {
	count(input.packages) > 10
	msg := sprintf("CONSIDER: module has %d packages — consider whether some can be consolidated", [count(input.packages)])
}

_has_exported_func(pkg) if {
	some file in pkg.files
	some f in file.funcs
	f.exported
}
