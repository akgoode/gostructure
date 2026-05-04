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
# description: >-
#   Packages with a constructor (New*) must export a Config struct declaring their
#   dependencies. The caller builds it from env vars, flags, or hardcoded values in
#   tests. The package never reaches outward for configuration. This makes
#   dependencies explicit, testing trivial, and deployment interchangeable.
violation_missing_config contains obj if {
	has_constructor
	not has_config_struct
	obj := {
		"msg": "constructor exists but no Config struct exported. Add: type Config struct { ... }",
		"rule_id": "GO-CFG-001",
		"severity": "error",
	}
}

# METADATA
# title: Constructor does not accept Config
# description: >-
#   When both a Config struct and constructor exist, the constructor must accept
#   Config as a parameter so the caller controls all configuration in one place.
#   The constructor signature should be New(cfg Config) (*T, error).
violation_disconnected_config contains obj if {
	has_constructor
	has_config_struct
	not constructor_takes_config
	obj := {
		"msg": "constructor does not accept Config. Change signature to New(cfg Config) (*T, error)",
		"rule_id": "GO-CFG-002",
		"severity": "error",
	}
}
