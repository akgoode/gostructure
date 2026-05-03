package main

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

deny contains msg if {
	some pkg in input.packages
	pkg.package in layer_names
	msg := sprintf("%s — package named after a technical layer; name packages after what they do, not what architectural role they play", [pkg.path])
}

deny contains msg if {
	some pkg in input.packages
	not _has_exported_func(pkg)
	msg := sprintf("%s — package '%s' has no exported funcs; every package should provide at least one", [pkg.path, pkg.package])
}

_has_exported_func(pkg) if {
	some file in pkg.files
	some f in file.funcs
	f.exported
}

warn contains msg if {
	count(input.packages) > 10
	msg := sprintf("module has %d packages — consider whether some can be consolidated", [count(input.packages)])
}
