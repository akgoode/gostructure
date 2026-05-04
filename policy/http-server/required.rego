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
# description: >
#   Every HTTP server package must export New(cfg Config) (*Server, error) or
#   NewServer(...). The constructor wires dependencies and returns the server.
violation_missing_constructor contains obj if {
	not has_exported_func("New")
	not has_exported_func("NewServer")
	obj := {
		"msg": concat("\n", [
			"MISSING: New(cfg Config) (*Server, error)",
			"",
			"Every HTTP server package must export a constructor that wires dependencies",
			"and returns the server. The constructor receives a Config struct (or individual",
			"dependencies) and returns the assembled server ready to start.",
			"",
			"The constructor is where dependency injection happens — database connections,",
			"external API clients, and middleware are wired here. The caller (main.go or a",
			"test) provides the dependencies; the constructor assembles them.",
			"",
			"Example:",
			"  type Server struct {",
			"      mux    *http.ServeMux",
			"      store  store",
			"      logger *slog.Logger",
			"  }",
			"",
			"  func New(cfg Config) (*Server, error) {",
			"      db, err := sql.Open(\"postgres\", cfg.DatabaseURL)",
			"      if err != nil {",
			"          return nil, fmt.Errorf(\"connect to database: %w\", err)",
			"      }",
			"      s := &Server{",
			"          mux:    http.NewServeMux(),",
			"          store:  &pgStore{db: db},",
			"          logger: cfg.Logger,",
			"      }",
			"      s.routes()",
			"      return s, nil",
			"  }",
		]),
		"rule_id": "GO-HTTP-001",
		"severity": "error",
	}
}

# METADATA
# title: Missing Routes function
# description: >
#   Every HTTP server must export Routes() as the table of contents for all
#   endpoints. Keep it flat — no logic, no middleware wiring.
violation_missing_routes contains obj if {
	not has_exported_func("Routes")
	obj := {
		"msg": concat("\n", [
			"MISSING: Routes(mux *http.ServeMux)",
			"",
			"Every HTTP server package must export a function that registers all routes on",
			"the given mux. This is the table of contents for the API — a reader opens this",
			"function and sees every endpoint the server handles.",
			"",
			"Keep this function as a flat list of route registrations. No logic, no",
			"middleware wiring, no conditionals. Each line maps a pattern to a handler.",
			"If the list gets long, that's a signal the server has too many responsibilities.",
			"",
			"Example:",
			"  func (s *Server) Routes() {",
			"      s.mux.HandleFunc(\"GET /health\", s.handleHealth)",
			"      s.mux.HandleFunc(\"GET /orders\", s.handleListOrders)",
			"      s.mux.HandleFunc(\"POST /orders\", s.handleCreateOrder)",
			"      s.mux.HandleFunc(\"GET /orders/{id}\", s.handleGetOrder)",
			"  }",
		]),
		"rule_id": "GO-HTTP-002",
		"severity": "error",
	}
}

# METADATA
# title: Missing Health function
# description: >
#   Every HTTP server must export Health() for Kubernetes readiness/liveness
#   probes. Check all critical dependencies and return structured status.
violation_missing_health contains obj if {
	not has_exported_func("Health")
	obj := {
		"msg": concat("\n", [
			"MISSING: Health() HealthStatus",
			"",
			"Every HTTP server must export a Health function that returns the current",
			"service health. This is called by Kubernetes readiness and liveness probes",
			"to determine if the service can accept traffic.",
			"",
			"The function should check all critical dependencies (database connectivity,",
			"cache availability, external API reachability) and return a HealthStatus",
			"struct with the overall status and per-component details. A degraded",
			"dependency should degrade the overall status, not crash the probe.",
			"",
			"Example:",
			"  type HealthStatus struct {",
			"      Status     string            `json:\"status\"`",
			"      Components map[string]string `json:\"components\"`",
			"  }",
			"",
			"  func (s *Server) Health() HealthStatus {",
			"      status := HealthStatus{",
			"          Status:     \"healthy\",",
			"          Components: make(map[string]string),",
			"      }",
			"      if err := s.db.Ping(); err != nil {",
			"          status.Status = \"degraded\"",
			"          status.Components[\"database\"] = err.Error()",
			"      } else {",
			"          status.Components[\"database\"] = \"ok\"",
			"      }",
			"      return status",
			"  }",
		]),
		"rule_id": "GO-HTTP-003",
		"severity": "error",
	}
}
