package layout

import rego.v1

# METADATA
# title: shared/ package too large
# description: >-
#   The shared kernel (internal/shared/) holds cross-cutting concerns like
#   middleware, error types, and response helpers. It should stay thin — 6
#   non-test files max. If it grows beyond that, domain-specific logic has
#   leaked in and should be extracted into its own domain package.
warn contains msg if {
	some pkg in input.packages
	_is_shared_package(pkg)
	non_test := [f | some f in pkg.files; not f.is_test]
	count(non_test) > 6
	msg := sprintf("GO-LAY-001: %s — shared package has %d non-test files (max 6). Move domain-specific code into its own package.", [pkg.path, count(non_test)])
}

# METADATA
# title: Domain package missing expected files
# description: >-
#   Domain packages directly under internal/ that have a constructor (New*) are
#   expected to follow the domain layout: service.go for business logic and
#   models.go for domain types. Missing files suggest the domain is either
#   incomplete or mixing concerns into fewer files. Only applies to top-level
#   internal/ packages — sub-packages within a domain are free to organize
#   however they need.
warn contains msg if {
	some pkg in input.packages
	_is_domain_package(pkg)
	_has_constructor(pkg)
	some expected in {"service.go", "models.go"}
	not _has_file(pkg, expected)
	msg := sprintf("GO-LAY-002: %s — domain package missing '%s'. Expected layout: service.go, models.go, and handler.go or worker.go.", [pkg.path, expected])
}

# METADATA
# title: Package outside expected top-level directories
# description: >-
#   Go applications should keep nearly all code under internal/. The only
#   expected top-level directories are cmd/ (entry points), api/ (protobuf
#   or OpenAPI definitions), internal/ (everything else), gen/ (generated
#   code), and client/ (importable SDK). Packages outside these directories
#   are importable by other modules — if that is not intentional, move them
#   under internal/.
warn contains msg if {
	some pkg in input.packages
	not _is_under_expected_dir(pkg)
	msg := sprintf("GO-LAY-003: %s — package '%s' is outside cmd/, api/, and internal/. Most application code should be under internal/.", [pkg.path, pkg.package])
}

_allowed_top_level := {"cmd", "api", "internal", "gen", "client"}

_is_under_expected_dir(pkg) if {
	some dir in _allowed_top_level
	contains(pkg.path, concat("", ["/", dir, "/"]))
}

_is_under_expected_dir(pkg) if {
	some dir in _allowed_top_level
	startswith(pkg.path, concat("", [dir, "/"]))
}

_is_under_expected_dir(pkg) if {
	segments := split(pkg.path, "/")
	clean := [s | some s in segments; s != "."; s != ""]
	count(clean) >= 1
	clean[0] in _allowed_top_level
}

_is_internal_package(pkg) if contains(pkg.path, "/internal/")

_is_internal_package(pkg) if startswith(pkg.path, "internal/")

_is_shared_package(pkg) if {
	_is_internal_package(pkg)
	pkg.package == "shared"
}

_is_domain_package(pkg) if {
	_is_top_level_internal(pkg)
	not _is_shared_package(pkg)
}

_is_top_level_internal(pkg) if {
	segments := split(pkg.path, "/")
	count(segments) >= 2
	segments[count(segments) - 2] == "internal"
}

_has_constructor(pkg) if {
	some file in pkg.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	startswith(f.name, "New")
}

_has_file(pkg, name) if {
	some file in pkg.files
	file.name == name
}
