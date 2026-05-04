package worker

import rego.v1

has_exported_func(name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.name == name
}

# METADATA
# title: Missing worker constructor
# description: >-
#   Every worker package must export New(cfg Config) (*Worker, error) or
#   NewWorker(...). The constructor wires dependencies and validates that they
#   are reachable. The worker struct holds everything RunOnce needs.
violation_missing_constructor contains obj if {
	not has_exported_func("New")
	not has_exported_func("NewWorker")
	obj := {
		"msg": "missing constructor. Add: func New(cfg Config) (*Worker, error)",
		"rule_id": "GO-WORK-001",
		"severity": "error",
	}
}

# METADATA
# title: Missing RunOnce function
# description: >-
#   Every worker must export RunOnce(ctx context.Context) error. It performs a
#   single idempotent execution cycle — find work, process it, record outcome.
#   Must be safe to call repeatedly. If no work exists, returns nil. Context
#   carries cancellation signals from the caller.
violation_missing_runonce contains obj if {
	not has_exported_func("RunOnce")
	obj := {
		"msg": "missing RunOnce. Add: func (w *Worker) RunOnce(ctx context.Context) error",
		"rule_id": "GO-WORK-002",
		"severity": "error",
	}
}
