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
