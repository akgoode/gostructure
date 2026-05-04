package main

import rego.v1

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

test_packages := {
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

deny contains msg if {
	some file in input.files
	not file.is_test
	some imp in file.imports
	imp in test_packages
	msg := sprintf("%s\n%s", [
		sprintf("%s — imports test package '%s' in production code", [file.name, imp]),
		concat("\n", [
			"",
			"Test dependencies must stay in test files. Importing a test framework in",
			"production code means the framework becomes a runtime dependency — it ships",
			"in the binary, increases the attack surface, and creates confusion about",
			"what's test infrastructure vs. what's real.",
			"",
			"If you need assertions or mocks in production code, you're looking for",
			"validation (use explicit checks and return errors) or interfaces (define",
			"a small interface and pass a real implementation).",
		]),
	])
}
