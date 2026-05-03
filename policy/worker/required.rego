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
	not has_exported_func("NewWorker")
	msg := "package must export New(cfg Config) (*Worker, error) or NewWorker — constructor that wires dependencies and returns the worker"
}

deny contains msg if {
	not has_exported_func("RunOnce")
	msg := "package must export RunOnce(ctx context.Context) error — single execution cycle of the worker loop"
}
