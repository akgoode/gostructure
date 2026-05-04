package errors

import rego.v1

_has_public_methods(ns) if {
	some t in ns.types
	t.kind == "class"
	t.is_public
	not t.is_static
	some m in t.methods
	m.is_public
}

_has_exception_types(ns) if {
	some t in ns.types
	t.kind == "class"
	t.is_public
	t.base_type != null
	_is_exception_base(t.base_type)
}

_is_exception_base(base) if { base == "Exception" }
_is_exception_base(base) if { endswith(base, "Exception") }

# METADATA
# title: Missing domain exception types
# description: >-
#   Namespaces with public service classes should define custom exception types
#   that describe what can go wrong. Custom exceptions make the codebase searchable,
#   tests precise, and give callers a contract. Throw OrderNotFoundException, not
#   InvalidOperationException with a magic string.
violation_missing_exceptions contains obj if {
	some ns in input.namespaces
	_has_public_methods(ns)
	not _has_exception_types(ns)
	obj := {
		"msg": sprintf("%s — public services but no custom exception types. Add domain exceptions (e.g., OrderNotFoundException).", [ns.namespace]),
		"rule_id": "NET-ERR-001",
		"severity": "error",
	}
}
