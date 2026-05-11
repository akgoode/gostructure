package imports

import rego.v1

# METADATA
# title: Too many imports
# description: >-
#   Files importing more than 8 packages are pulling in too many concerns. Each
#   import is a dependency on someone else's API, behavior, and release cycle.
#   Split the file along import clusters — a file that imports both database
#   drivers and HTTP routers is doing two jobs.
warn contains msg if {
	some file in input.files
	not file.is_test
	count(file.imports) > 8
	msg := sprintf("CONSIDER: %s — %d imports (max 8). Split file by concept.", [file.name, count(file.imports)])
}

_test_packages := {
	"github.com/stretchr/testify",
	"github.com/stretchr/testify/assert",
	"github.com/stretchr/testify/require",
	"github.com/stretchr/testify/mock",
	"github.com/stretchr/testify/suite",
	"go.uber.org/mock",
	"go.uber.org/mock/gomock",
	"github.com/golang/mock",
	"github.com/golang/mock/gomock",
}

# METADATA
# title: Test package in production code
# description: >-
#   Test frameworks (testify, gomock) must not be imported in non-test files.
#   They become runtime dependencies, increase binary size, and confuse the
#   boundary between test infrastructure and production code. Use explicit
#   checks and return errors for validation; define small interfaces for mocking.
violation_test_import contains obj if {
	some file in input.files
	not file.is_test
	some imp in file.imports
	imp in _test_packages
	obj := {
		"msg": sprintf("%s — imports test package '%s' in production code", [file.name, imp]),
		"rule_id": "GO-IMP-001",
		"severity": "error",
		"_loc": {"file": file.name},
	}
}
