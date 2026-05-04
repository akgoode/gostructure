package config

import rego.v1

_service_types := [t |
	some ns in input.namespaces
	some t in ns.types
	t.kind == "class"
	t.is_public
	not t.is_static
	not t.is_abstract
	_has_di_constructor(t)
]

_has_di_constructor(t) if {
	some c in t.constructors
	c.is_public
	some p in c.parameters
	startswith(p.type, "I")
}

_options_types := {name |
	some ns in input.namespaces
	some t in ns.types
	t.is_public
	t.kind == "class"
	endswith(t.name, "Options")
	name := t.name
}

_constructor_takes_options(t) if {
	some c in t.constructors
	c.is_public
	some p in c.parameters
	endswith(p.type, "Options")
}

_constructor_takes_ioptions(t) if {
	some c in t.constructors
	c.is_public
	some p in c.parameters
	startswith(p.type, "IOptions<")
}

# METADATA
# title: Service class missing Options type
# description: >-
#   Service classes with constructor injection should have a corresponding Options
#   class for configuration. The Options class declares what the service needs
#   from configuration — timeouts, limits, feature flags. Register it with
#   services.Configure<TOptions>(configuration) in the DI container.
violation_missing_options contains obj if {
	some t in _service_types
	some ns in input.namespaces
	some st in ns.types
	st.name == t.name
	not _has_matching_options(t.name)
	obj := {
		"msg": sprintf("%s — service class with DI but no corresponding Options class. Add %sOptions.", [t.name, t.name]),
		"rule_id": "NET-CFG-001",
		"severity": "error",
	}
}

# METADATA
# title: Constructor takes concrete types instead of interfaces
# description: >-
#   Constructor parameters (excluding primitives, Options, ILogger, and well-known
#   framework types) should be interfaces, not concrete classes. Concrete dependencies
#   make the type impossible to test in isolation and violate dependency inversion.
violation_concrete_dependency contains obj if {
	some ns in input.namespaces
	some t in ns.types
	t.kind == "class"
	t.is_public
	not t.is_static
	not _is_exception_type(t)
	some c in t.constructors
	c.is_public
	some p in c.parameters
	_is_concrete_dependency(p)
	obj := {
		"msg": sprintf("%s constructor — parameter '%s' has concrete type '%s'. Depend on an interface instead.", [t.name, p.name, p.type]),
		"rule_id": "NET-CFG-002",
		"severity": "error",
	}
}

_is_exception_type(t) if {
	t.base_type != null
	endswith(t.base_type, "Exception")
}

_is_exception_type(t) if {
	t.base_type == "Exception"
}

_has_matching_options(type_name) if {
	expected := concat("", [type_name, "Options"])
	expected in _options_types
}

_is_concrete_dependency(param) if {
	not startswith(param.type, "I")
	not _is_framework_type(param.type)
	not endswith(param.type, "Options")
	not endswith(param.type, "Config")
	not endswith(param.type, "Settings")
	not _is_primitive(param.type)
	regex.match(`^[A-Z]`, param.type)
}

_is_framework_type(t) if { startswith(t, "IOptions<") }
_is_framework_type(t) if { startswith(t, "ILogger<") }
_is_framework_type(t) if { t == "ILogger" }
_is_framework_type(t) if { t == "IConfiguration" }
_is_framework_type(t) if { startswith(t, "IOptionsMonitor<") }
_is_framework_type(t) if { startswith(t, "IOptionsSnapshot<") }

_is_primitive(t) if { t in {"string", "int", "long", "bool", "double", "float", "decimal", "Guid", "DateTime", "TimeSpan", "CancellationToken"} }
