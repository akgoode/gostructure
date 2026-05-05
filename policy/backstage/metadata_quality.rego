package best_practices_all

import data.util_backstage
import rego.v1

# #7101 — All entities should have a description
deny_missing_description contains error if {
	not input.metadata.description
	error := sprintf(
		"Warning #7101 - Missing 'metadata.description' in %s '%s'. A good description helps users understand the entity's purpose",
		[input.kind, input.metadata.name],
	)
}

# #7102 — Description should be meaningful (>= 20 chars)
deny_short_description contains error if {
	desc := input.metadata.description
	count(desc) < 20
	error := sprintf(
		"Warning #7102 - Description in %s '%s' is too short (%d chars). Provide at least 20 characters",
		[input.kind, input.metadata.name, count(desc)],
	)
}

# #7104 — All entities should have tags for discoverability
deny_missing_tags contains error if {
	not input.metadata.tags
	error := sprintf(
		"Warning #7104 - No tags defined in %s '%s'. Tags improve discoverability in the catalog",
		[input.kind, input.metadata.name],
	)
}

deny_empty_tags contains error if {
	input.metadata.tags
	count(input.metadata.tags) == 0
	error := sprintf(
		"Warning #7104 - Empty tags list in %s '%s'. Add at least one tag",
		[input.kind, input.metadata.name],
	)
}

# Entity should have a human-friendly title
deny_missing_title contains error if {
	not input.metadata.title
	error := sprintf(
		"Warning #7109 - Missing 'metadata.title' in %s '%s'. A human-friendly title is shown in the Backstage UI",
		[input.kind, input.metadata.name],
	)
}

# #7107 — Component should reference a system
deny_component_missing_system contains error if {
	util_backstage.is_kind("Component")
	not input.spec.system
	error := sprintf(
		"Warning #7107 - Component '%s' is not associated with a system. Consider adding 'spec.system'",
		[input.metadata.name],
	)
}

# #7108 — System should reference a domain
deny_system_missing_domain contains error if {
	util_backstage.is_kind("System")
	not input.spec.domain
	error := sprintf(
		"Warning #7108 - System '%s' is not associated with a domain. Consider adding 'spec.domain'",
		[input.metadata.name],
	)
}
