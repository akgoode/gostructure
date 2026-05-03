package main

import rego.v1

has_exported_func(name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.name == name
}

deny contains msg if {
	not has_exported_func("New")
	not has_exported_func("NewServer")
	msg := "package must export New(cfg Config) (*Server, error) or NewServer — constructor that wires dependencies and returns the server"
}

deny contains msg if {
	not has_exported_func("Routes")
	msg := "package must export Routes(mux) — registers HTTP routes on the given mux"
}

deny contains msg if {
	not has_exported_func("Health")
	msg := "package must export Health() HealthStatus — returns service health for readiness probes"
}
