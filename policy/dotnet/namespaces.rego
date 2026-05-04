package namespaces

import rego.v1

_layer_names := {
	"Services",
	"Repositories",
	"Helpers",
	"Utils",
	"Utilities",
	"Common",
	"Managers",
	"Handlers",
	"Controllers",
	"Models",
	"ViewModels",
}

# METADATA
# title: Layer-named namespace segment
# description: >-
#   Namespaces with terminal segments named after technical layers (Services,
#   Repositories, Helpers, Utils) group code by role instead of by domain. This
#   creates grab-bag namespaces that grow unbounded. Name namespaces after what
#   they do — Orders, Auth, Billing — so a reader can find the right namespace
#   by guessing its name.
violation_layer_name contains obj if {
	some ns in input.namespaces
	segment := _last_segment(ns.namespace)
	segment in _layer_names
	obj := {
		"msg": sprintf("%s — namespace named after a technical layer. Name it after what it does.", [ns.namespace]),
		"rule_id": "NET-NS-001",
		"severity": "error",
	}
}

# METADATA
# title: Namespace has no public types
# description: >-
#   Every namespace should have at least one public type. A namespace with no
#   public API is dead code or misplaced internal logic that should be merged
#   into its consumer.
violation_no_public_types contains obj if {
	some ns in input.namespaces
	not _has_public_type(ns)
	obj := {
		"msg": sprintf("%s — namespace has no public types", [ns.namespace]),
		"rule_id": "NET-NS-002",
		"severity": "error",
	}
}

# METADATA
# title: Too many namespaces in assembly
# description: >-
#   Assemblies with more than 15 namespaces may have over-decomposed. Consider
#   whether some namespaces are thin wrappers that should be consolidated.
warn contains msg if {
	count(input.namespaces) > 15
	msg := sprintf("CONSIDER: assembly has %d namespaces (max 15). Consider consolidating.", [count(input.namespaces)])
}

_last_segment(namespace) := segment if {
	parts := split(namespace, ".")
	segment := parts[count(parts) - 1]
}

_has_public_type(ns) if {
	some t in ns.types
	t.is_public
}
