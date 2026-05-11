package httpserver

import rego.v1

has_exported_func(name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.name == name
}

# METADATA
# title: Missing HTTP server constructor
# description: >-
#   Every HTTP server package must export New(cfg Config) (*Server, error) or
#   NewServer(...). The constructor wires dependencies (database, clients,
#   middleware) and returns the assembled server. The caller provides dependencies;
#   the constructor assembles them.
violation_missing_constructor contains obj if {
	not has_exported_func("New")
	not has_exported_func("NewServer")
	obj := {
		"msg": "missing constructor. Add: func New(cfg Config) (*Server, error)",
		"rule_id": "GO-HTTP-001",
		"severity": "error",
	}
}

# METADATA
# title: Missing Routes function
# description: >-
#   Every HTTP server must export Routes() as the table of contents for all
#   endpoints. Keep it as a flat list of route registrations — no logic, no
#   middleware wiring, no conditionals. If the list gets long, the server has
#   too many responsibilities.
violation_missing_routes contains obj if {
	not has_exported_func("Routes")
	obj := {
		"msg": "missing Routes. Add: func (s *Server) Routes()",
		"rule_id": "GO-HTTP-002",
		"severity": "error",
	}
}

# METADATA
# title: Missing Health function
# description: >-
#   Every HTTP server must export Health() for Kubernetes readiness/liveness
#   probes. Check all critical dependencies (database, cache, external APIs)
#   and return structured status. A degraded dependency degrades overall status
#   but does not crash the probe.
violation_missing_health contains obj if {
	not has_exported_func("Health")
	obj := {
		"msg": "missing Health. Add: func (s *Server) Health() HealthStatus",
		"rule_id": "GO-HTTP-003",
		"severity": "error",
	}
}

# _is_handler_signature is true when a function takes both http.ResponseWriter
# and *http.Request — the canonical handler shape regardless of the function's
# name. This catches handlers whether they're called Handle*, Get*, or
# anything else.
_is_handler_signature(f) if {
	some p in f.params
	p.type == "http.ResponseWriter"
	some q in f.params
	q.type == "*http.Request"
}

# METADATA
# title: Top-level HTTP handler
# description: >-
#   HTTP handlers must be methods on the Server type (or closures returned by
#   factory functions), never package-level functions. A package-scope handler
#   has no clean way to access dependencies — it forces package-level state
#   (globals, init() side effects, or hidden singletons), all of which break
#   the dependency-injection contract every other server rule depends on.
#
#   Two acceptable patterns:
#     func (s *Server) handleProducts(w http.ResponseWriter, r *http.Request)
#     func createProduct(store *Store) http.HandlerFunc { return func(...) {...} }
#
#   The closure factory takes deps and returns a HandlerFunc — the handler
#   itself doesn't appear in the inventory as a top-level (w, r) function.
violation_top_level_handler contains obj if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.receiver == ""
	_is_handler_signature(f)
	obj := {
		"msg": sprintf("%s:%d — '%s' is a package-level HTTP handler. Move it to a method on *Server, or return it from a closure factory that takes its dependencies.", [file.name, f.line, f.name]),
		"rule_id": "GO-HTTP-004",
		"severity": "error",
		"_loc": {"file": file.name, "line": f.line},
	}
}

# _struct_types_in_package collects the names of all structs declared in the
# package's non-test files. Used to verify that a function's return type is
# a real struct defined here (not a primitive, map, slice, or external type).
_struct_types_in_package contains name if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
	name := t.name
}

# _returns_local_struct is true when any of f's return types matches a struct
# defined in this package. A single leading `*` is stripped so pointer returns
# like `*HealthStatus` resolve to `HealthStatus`. Double-pointers (`**Foo`) are
# left intact and will not match — those are pathological in real Go code and
# do not satisfy the Health-contract intent of this rule.
_returns_local_struct(f) if {
	some r in f.returns
	r in _struct_types_in_package
}

_returns_local_struct(f) if {
	some r in f.returns
	startswith(r, "*")
	not startswith(r, "**")
	substring(r, 1, -1) in _struct_types_in_package
}

# METADATA
# title: Health does not return a struct
# description: >-
#   Health() must return a struct type defined in this package, not a string,
#   map, error, or primitive. The struct is the contract callers program
#   against — fields like Status, Version, Dependencies. A string or map
#   loses the contract: callers can't pattern-match shape, the JSON envelope
#   isn't pinned, and tests can't assert on field-by-field behavior.
#
#   Pointer returns (*HealthStatus) are accepted; multi-value returns are
#   accepted as long as one of the returned types is a local struct.
#
#   This rule only fires when Health exists. If Health is missing entirely,
#   GO-HTTP-003 fires instead.
violation_health_invalid_return contains obj if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.name == "Health"
	f.exported
	not _returns_local_struct(f)
	obj := {
		"msg": sprintf("%s:%d — Health() must return a struct type defined in this package (e.g. HealthStatus), not a primitive, map, or external type.", [file.name, f.line]),
		"rule_id": "GO-HTTP-005",
		"severity": "error",
		"_loc": {"file": file.name, "line": f.line},
	}
}

# _pkg_imports collects every import path used by the package's non-test
# files. Test files are excluded because the rule is about what the
# production code imports — test fixtures may need different deps.
_pkg_imports contains imp if {
	some file in input.files
	not file.is_test
	some imp in file.imports
}

# _has_prom_import is true when any production file imports anything under
# the prometheus/client_golang module — the canonical client/promhttp/testutil
# subpackages all qualify.
_has_prom_import if {
	some imp in _pkg_imports
	startswith(imp, "github.com/prometheus/client_golang/")
}

# METADATA
# title: HTTP server package missing log/slog import
# description: >-
#   HTTP server packages must use log/slog for structured, request-scoped
#   logging. The middleware chain attaches a per-request logger to context;
#   handlers retrieve it for domain-level events. Without slog, logs become
#   ad-hoc strings that can't be filtered, correlated, or shipped to a
#   structured sink.
violation_missing_required_import contains obj if {
	not "log/slog" in _pkg_imports
	obj := {
		"msg": "HTTP server package must import log/slog for structured request-scoped logging.",
		"rule_id": "GO-HTTP-006",
		"severity": "error",
	}
}

# METADATA
# title: HTTP server package missing Prometheus client import
# description: >-
#   HTTP server packages must expose RED metrics (rate, errors, duration)
#   via the github.com/prometheus/client_golang client. Any subpackage
#   (prometheus, promhttp, testutil, etc.) satisfies this. Without it, the
#   metrics middleware has no collector to register against and the /metrics
#   endpoint cannot be wired.
violation_missing_required_import contains obj if {
	not _has_prom_import
	obj := {
		"msg": "HTTP server package must import github.com/prometheus/client_golang/* for RED metrics.",
		"rule_id": "GO-HTTP-006",
		"severity": "error",
	}
}
