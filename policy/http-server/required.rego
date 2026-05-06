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
