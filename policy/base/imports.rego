package imports

import rego.v1

# METADATA
# title: Too many imports
# description: >
#   Files importing more than 8 packages are pulling in too many concerns.
#   Split the file along import clusters.
warn contains msg if {
	some file in input.files
	not file.is_test
	count(file.imports) > 8
	msg := sprintf("%s\n%s", [
		sprintf("CONSIDER: %s — file has %d imports (max 8)", [file.name, count(file.imports)]),
		concat("\n", [
			"",
			"A file importing this many packages is pulling in too many concerns. Each",
			"import is a dependency — on someone else's API, behavior, and release",
			"cycle. When a file imports heavily, it's usually because the file is doing",
			"too many things, not because the task genuinely needs that many tools.",
			"",
			"Look for which imports cluster together and split the file along those",
			"lines. A file that imports both database drivers and HTTP routers is doing",
			"two jobs. A file that imports 4 encoding packages is doing one job — that's",
			"fine, even if the count is high.",
			"",
			"The fix is the same as for too many functions: split by concept, not by",
			"role. Each file should have a focused set of imports that all serve the",
			"same purpose.",
		]),
	])
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
# description: >
#   Test frameworks must not be imported in non-test files. They become runtime
#   dependencies, increase binary size, and confuse the boundary between test
#   infrastructure and production code.
violation_test_import contains obj if {
	some file in input.files
	not file.is_test
	some imp in file.imports
	imp in _test_packages
	obj := {
		"msg": sprintf("%s — imports test package '%s' in production code. Test dependencies must stay in test files.", [file.name, imp]),
		"rule_id": "GO-IMP-001",
		"severity": "error",
		"_loc": {"file": file.name},
	}
}
