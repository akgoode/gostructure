package errors

import rego.v1

has_error_returns if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.returns_error
}

has_domain_errors if {
	some file in input.files
	not file.is_test
	some v in file.vars
	startswith(v.name, "Err")
}

has_domain_errors if {
	some file in input.files
	not file.is_test
	some t in file.types
	endswith(t.name, "Error")
}

# METADATA
# title: Missing domain error types
# description: >
#   Packages with exported functions that return error must define domain errors
#   (sentinel vars or error types). This makes the codebase searchable, tests
#   precise, and gives callers a contract.
violation_missing_domain_errors contains obj if {
	has_error_returns
	not has_domain_errors
	obj := {
		"msg": concat("\n", [
			"MISSING: domain error types",
			"",
			"This package has exported functions that return error but defines no domain",
			"error types. Every package that returns errors should define sentinel errors",
			"(var Err* = errors.New(...)) or error types (type *Error struct).",
			"",
			"Domain errors make the codebase searchable — grep for ErrNotFound to see",
			"every place that condition is handled. They make tests precise — assert on",
			"a specific error, not a substring. And they give callers a contract: these",
			"are the things that can go wrong.",
			"",
			"Use sentinel errors for simple conditions:",
			"  var ErrNotFound = errors.New(\"order not found\")",
			"  var ErrAlreadyProcessed = errors.New(\"order already processed\")",
			"",
			"Use error types when the caller needs structured details:",
			"  type ValidationError struct {",
			"      Field   string",
			"      Message string",
			"  }",
			"  func (e *ValidationError) Error() string {",
			"      return fmt.Sprintf(\"%s: %s\", e.Field, e.Message)",
			"  }",
			"",
			"Then return them from your functions:",
			"  func (s *Store) Order(ctx context.Context, id string) (Order, error) {",
			"      row := s.db.QueryRowContext(ctx, query, id)",
			"      if err := row.Scan(&o); err == sql.ErrNoRows {",
			"          return Order{}, ErrNotFound",
			"      }",
			"      return o, nil",
			"  }",
		]),
		"rule_id": "GO-ERR-001",
		"severity": "error",
	}
}
