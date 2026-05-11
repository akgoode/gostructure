package structure

import rego.v1

# METADATA
# title: No global mutable variables
# description: >-
#   Package-level vars create hidden coupling, race conditions, and make testing
#   impossible without global state mutation. The fix is to make it a const, move
#   it inside the function that uses it, or return it from a constructor.
#   Exempt: error sentinels (Err*) and throwaway (_). Respects allow-globals tag.
violation_global_vars contains obj if {
	some file in input.files
	not file.is_test
	not "allow-globals" in _file_tags(file)
	some v in file.vars
	v.name != "_"
	not startswith(v.name, "Err")
	obj := {
		"msg": sprintf("%s:%d — var '%s': use const, move to function scope, or return from constructor", [file.name, v.line, v.name]),
		"rule_id": "GO-STRUCT-001",
		"severity": "error",
		"_loc": {"file": file.name, "line": v.line},
	}
}

# METADATA
# title: Interface too large
# description: >-
#   Interfaces with more than 5 methods create tight coupling. Every implementation
#   must satisfy every method, and every consumer depends on methods it doesn't call.
#   Define interfaces where they're consumed, with only the methods that caller needs.
#   A 5-method CRUD interface (list, get, create, update, delete) is the legitimate max.
warn contains msg if {
	some file in input.files
	some t in file.types
	t.kind == "interface"
	count(t.methods) > 5
	msg := sprintf("CONSIDER: %s:%d — interface '%s' has %d methods (max 5). Split into consumer-specific interfaces.", [file.name, t.line, t.name, count(t.methods)])
}

# METADATA
# title: Too many functions in file
# description: >-
#   Files with more than 10 non-test functions are doing too many things. Each file
#   should represent one concept. Look for function clusters that share a receiver,
#   form a pipeline, or could be described with a single noun, and move them to
#   their own file named after what they do.
warn contains msg if {
	some file in input.files
	not file.is_test
	funcs := [f | some f in file.funcs; not startswith(f.name, "Test")]
	count(funcs) > 10
	msg := sprintf("SHOULD: %s — %d functions (max 10). Split by concept.", [file.name, count(funcs)])
}

# METADATA
# title: Too many function parameters
# description: >-
#   Beyond 4 parameters, the combinatorial state space makes the function hard to
#   test exhaustively and hard to call correctly. Group related parameters into a
#   named struct. If they travel as a set, they're a concept that deserves a name.
warn contains msg if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	count(f.params) > 4
	msg := sprintf("SHOULD: %s:%d — %s has %d params (max 4). Group into a struct.", [file.name, f.line, f.name, count(f.params)])
}

# METADATA
# title: Too many return values
# description: >-
#   Go convention is (result, error) at most. Beyond 2 return values, the function
#   is computing multiple things and the caller juggles them all. Group results into
#   a named struct for self-documentation and future extensibility.
warn contains msg if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	count(f.returns) > 2
	msg := sprintf("SHOULD: %s:%d — %s returns %d values (max 2). Wrap in a struct.", [file.name, f.line, f.name, count(f.returns)])
}

# METADATA
# title: Struct has too many fields
# description: >-
#   Structs with more than 8 fields represent too many concepts. Each field
#   multiplies the state space. Look for fields that cluster together and extract
#   them into their own type. Config structs are exempt because they are flat by
#   design — each field maps to one external input (env var, flag, secret).
warn contains msg if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
	t.name != "Config"
	count(t.fields) > 8
	msg := sprintf("SHOULD: %s:%d — struct '%s' has %d fields (max 8). Extract field clusters into sub-types.", [file.name, t.line, t.name, count(t.fields)])
}

# METADATA
# title: Type has too many methods
# description: >-
#   Types with more than 10 methods accumulate too many responsibilities. Look for
#   method clusters that serve different purposes and extract them into separate types.
#   The original type holds the new one as a field and delegates.
warn contains msg if {
	some receiver in _type_receivers
	mc := _method_count(receiver)
	mc > 10
	msg := sprintf("CONSIDER: type '%s' has %d methods (max 10). Extract method clusters into separate types.", [receiver, mc])
}

# METADATA
# title: Exported struct missing constructor
# description: >-
#   Exported structs that hold injected dependencies (pointer fields or unexported
#   fields) AND carry behavior (have at least one method) need a New* constructor.
#   The constructor centralizes initialization so every caller assembles the same
#   valid instance.
#
#   Pure data types — domain values like Product, Money, request/response DTOs —
#   are deliberately exempt: they have no methods, no invariants beyond JSON tags,
#   and a constructor would be ceremony around a struct literal. The signal for
#   "this is a service, not data" is the presence of methods.
warn contains msg if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
	t.exported
	t.name != "Config"
	_method_count(t.name) > 0
	_has_fields_needing_setup(t)
	not _has_constructor_for(t.name)
	msg := sprintf("SHOULD: %s:%d — exported struct '%s' has no constructor. Add New%s(cfg Config) (*%s, error).", [file.name, t.line, t.name, t.name, t.name])
}

_method_count(receiver) := count([f |
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.receiver == receiver
])

_type_receivers contains t.name if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
}

# A struct has fields needing centralized setup if any field is a pointer
# (likely an injected dependency) or unexported (an invariant the
# constructor enforces). Package-qualified value types like time.Time or
# decimal.Decimal are NOT signals on their own — they appear routinely on
# pure data types and produced false positives in the previous version of
# this rule.
_has_fields_needing_setup(t) if {
	some f in t.fields
	startswith(f.type, "*")
}

_has_fields_needing_setup(t) if {
	some f in t.fields
	not f.exported
}

_has_constructor_for(type_name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name == "New"
}

_has_constructor_for(type_name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name == concat("", ["New", type_name])
}

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
