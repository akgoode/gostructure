package config

import rego.v1

has_constructor if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	startswith(f.name, "New")
}

has_config_struct if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.name == "Config"
	t.kind == "struct"
	t.exported
}

constructor_takes_config if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	startswith(f.name, "New")
	some p in f.params
	p.type == "Config"
}

# METADATA
# title: Missing Config struct
# description: >
#   Packages with a constructor (New*) must export a Config struct declaring their
#   dependencies. The caller builds it; the package never reaches outward.
violation_missing_config contains obj if {
	has_constructor
	not has_config_struct
	obj := {
		"msg": concat("\n", [
			"MISSING: Config struct",
			"",
			"This package has a constructor (New/New*) but no exported Config struct.",
			"Every package that needs configuration should declare what it needs by",
			"exporting a Config struct. The caller builds it — from env vars, flags,",
			"or hardcoded values in tests. The package never reaches outward for",
			"configuration.",
			"",
			"This makes dependencies explicit, testing trivial, and deployment",
			"interchangeable — the same package works behind a Lambda, an HTTP",
			"server, or a CLI without changing a line.",
			"",
			"Example:",
			"  type Config struct {",
			"      DatabaseURL  string",
			"      PollInterval time.Duration",
			"      Logger       *slog.Logger",
			"  }",
			"",
			"  func New(cfg Config) (*Worker, error) {",
			"      db, err := sql.Open(\"postgres\", cfg.DatabaseURL)",
			"      if err != nil {",
			"          return nil, fmt.Errorf(\"connect to database: %w\", err)",
			"      }",
			"      return &Worker{db: db, logger: cfg.Logger}, nil",
			"  }",
		]),
		"rule_id": "GO-CFG-001",
		"severity": "error",
	}
}

# METADATA
# title: Constructor does not accept Config
# description: >
#   When both a Config struct and constructor exist, the constructor must accept
#   Config as a parameter so the caller controls all configuration in one place.
violation_disconnected_config contains obj if {
	has_constructor
	has_config_struct
	not constructor_takes_config
	obj := {
		"msg": concat("\n", [
			"DISCONNECTED: constructor does not accept Config",
			"",
			"This package defines a Config struct and a constructor, but the constructor",
			"does not take Config as a parameter. Pass Config to New so the caller",
			"controls all configuration in one place.",
			"",
			"Example:",
			"  func New(cfg Config) (*Server, error) { ... }",
		]),
		"rule_id": "GO-CFG-002",
		"severity": "error",
	}
}
