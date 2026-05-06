package mandatory_all

import data.util_backstage
import rego.v1

# #7004 — Components and APIs must have annotations section
deny_missing_annotations contains error if {
	{"Component", "API"}[input.kind]
	not input.metadata.annotations
	error := sprintf(
		"Error #7004 - Missing 'metadata.annotations' in %s '%s'",
		[input.kind, input.metadata.name],
	)
}

# #7004 — Components must have dev.azure.com/project-repo or github.com/project-slug
deny_missing_source_annotation contains error if {
	util_backstage.is_kind("Component")
	input.metadata.annotations
	not util_backstage.has_annotation("dev.azure.com/project-repo")
	not util_backstage.has_annotation("github.com/project-slug")
	error := sprintf(
		"Error #7004 - Component '%s' is missing a source repo annotation. Add 'dev.azure.com/project-repo' or 'github.com/project-slug'",
		[input.metadata.name],
	)
}
