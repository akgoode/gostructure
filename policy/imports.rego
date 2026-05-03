package main

import rego.v1

# Customize: file names that are workflow orchestrations
workflow_files := {"handler.go", "workflow.go", "run.go"}

# Customize: imports that indicate implementation leaked into orchestration
impl_imports := {
	"database/sql",
	"net/http",
	"encoding/json",
	"encoding/xml",
	"os",
}

deny contains msg if {
	some file in input.files
	file.name in workflow_files
	some imp in file.imports
	imp in impl_imports
	msg := sprintf("%s — workflow file imports implementation package '%s'", [file.name, imp])
}
