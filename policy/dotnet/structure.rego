package structure

import rego.v1

_all_types := [t |
	some ns in input.namespaces
	some t in ns.types
]

_public_types := [t |
	some t in _all_types
	t.is_public
]

# METADATA
# title: No public static mutable fields
# description: >-
#   Public static fields that are neither readonly nor const create shared mutable
#   state — race conditions, hidden coupling, untestable code. Make the field
#   readonly, const, or move it behind a method/property with controlled access.
violation_mutable_static contains obj if {
	some ns in input.namespaces
	some t in ns.types
	some f in t.fields
	f.is_static
	f.is_public
	not f.is_readonly
	obj := {
		"msg": sprintf("%s.%s — public static mutable field '%s'. Make it readonly, const, or encapsulate behind a property.", [ns.namespace, t.name, f.name]),
		"rule_id": "NET-STRUCT-001",
		"severity": "error",
	}
}

# METADATA
# title: Interface too large
# description: >-
#   Interfaces with more than 5 methods force every implementation to satisfy methods
#   it may not need. Define interfaces where they are consumed with only the methods
#   that caller requires. A 5-method CRUD interface (list, get, create, update, delete)
#   is the legitimate max.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	t.kind == "interface"
	methods := [m | some m in t.methods; m.is_public]
	count(methods) > 5
	msg := sprintf("CONSIDER: %s.%s — interface has %d methods (max 5). Split into consumer-specific interfaces.", [ns.namespace, t.name, count(methods)])
}

# METADATA
# title: Too many public methods on type
# description: >-
#   Types with more than 15 public methods accumulate too many responsibilities.
#   Look for method clusters that serve different purposes and extract them into
#   separate types. The original type holds the new one as a field and delegates.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	t.kind == "class"
	not t.is_static
	pub := [m | some m in t.methods; m.is_public; not m.is_override]
	count(pub) > 15
	msg := sprintf("CONSIDER: %s.%s — %d public methods (max 15). Extract method clusters into separate types.", [ns.namespace, t.name, count(pub)])
}

# METADATA
# title: Too many method parameters
# description: >-
#   Beyond 4 parameters the combinatorial state space makes the method hard to test
#   and hard to call correctly. Group related parameters into a request object or
#   options class.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	some m in t.methods
	m.is_public
	count(m.parameters) > 4
	msg := sprintf("SHOULD: %s.%s.%s — %d params (max 4). Group into a request object.", [ns.namespace, t.name, m.name, count(m.parameters)])
}

# METADATA
# title: Too many constructor parameters
# description: >-
#   Constructors with more than 6 parameters indicate the type has too many
#   dependencies. Extract a group of related dependencies into a separate service
#   that this type delegates to.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	some c in t.constructors
	c.is_public
	count(c.parameters) > 6
	msg := sprintf("SHOULD: %s.%s constructor — %d params (max 6). Extract dependency clusters into separate services.", [ns.namespace, t.name, count(c.parameters)])
}

# METADATA
# title: Too many fields on type
# description: >-
#   Classes with more than 8 fields represent too many concepts. Each field
#   multiplies the state space. Look for fields that cluster together and extract
#   them into their own type. Options/Config classes are exempt because they are
#   flat by design.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	t.kind == "class"
	not endswith(t.name, "Options")
	not endswith(t.name, "Config")
	not endswith(t.name, "Settings")
	count(t.fields) > 8
	msg := sprintf("SHOULD: %s.%s — %d fields (max 8). Extract field clusters into sub-types.", [ns.namespace, t.name, count(t.fields)])
}

# METADATA
# title: Prefer sealed classes
# description: >-
#   Public non-abstract classes that are not sealed allow uncontrolled inheritance.
#   Seal classes by default and only unseal when you have designed for extension.
#   Exception types and Options/Config classes are exempt.
warn contains msg if {
	some ns in input.namespaces
	some t in ns.types
	t.kind == "class"
	t.is_public
	not t.is_sealed
	not t.is_abstract
	not t.is_static
	not _is_exception(t)
	not endswith(t.name, "Options")
	not endswith(t.name, "Config")
	not endswith(t.name, "Settings")
	msg := sprintf("CONSIDER: %s.%s — public class is not sealed. Seal by default; only unseal when designed for inheritance.", [ns.namespace, t.name])
}

_is_exception(t) if {
	t.base_type != null
	_inherits_exception(t.base_type)
}

_inherits_exception(base) if {
	base == "Exception"
}

_inherits_exception(base) if {
	endswith(base, "Exception")
}
