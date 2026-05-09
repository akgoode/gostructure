package packages

import rego.v1

# METADATA
# title: Package has no exported functions
# description: >-
#   Every package must export at least one function. A package with no public API
#   is dead code or misplaced internal logic that should be merged into its caller.
violation_no_exports contains obj if {
	some pkg in input.packages
	not _has_exported_func(pkg)
	obj := {
		"msg": sprintf("%s — package '%s' has no exported funcs", [pkg.path, pkg.package]),
		"rule_id": "GO-PKG-002",
		"severity": "error",
		"_loc": {"file": pkg.path},
	}
}

# METADATA
# title: Too many packages in module
# description: >-
#   Modules with more than 10 packages may have over-decomposed. Consider whether
#   some packages are thin wrappers that should be consolidated with their callers.
warn contains msg if {
	count(input.packages) > 10
	msg := sprintf("CONSIDER: module has %d packages (max 10). Consider consolidating.", [count(input.packages)])
}

_has_exported_func(pkg) if {
	some file in pkg.files
	some f in file.funcs
	f.exported
}
