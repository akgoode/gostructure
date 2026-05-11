package mandatory_all

import data.util_backstage
import rego.v1

# #7002 — apiVersion must be backstage.io/v1alpha1
deny_missing_api_version contains error if {
	not input.apiVersion
	error := "Error #7002 - Missing 'apiVersion' in backstage entity"
}

deny_invalid_api_version contains error if {
	input.apiVersion
	input.apiVersion != "backstage.io/v1alpha1"
	error := sprintf(
		"Error #7002 - Invalid 'apiVersion' '%s'. Expected 'backstage.io/v1alpha1'",
		[input.apiVersion],
	)
}

# #7002 — kind must be a valid Backstage entity kind
deny_missing_kind contains error if {
	not input.kind
	error := "Error #7002 - Missing 'kind' in backstage entity"
}

deny_invalid_kind contains error if {
	input.kind
	not util_backstage.valid_kinds[input.kind]
	error := sprintf(
		"Error #7002 - Invalid 'kind' '%s' in backstage entity",
		[input.kind],
	)
}

# #7004 — metadata must exist
deny_missing_metadata contains error if {
	not input.metadata
	error := "Error #7004 - Missing 'metadata' in backstage entity"
}

# #7004 — metadata.name is required
deny_missing_name contains error if {
	not input.metadata.name
	error := "Error #7004 - Missing 'metadata.name' in backstage entity"
}

# #7004 — metadata.name must be lowercase kebab-case, max 63 chars
deny_invalid_name contains error if {
	name := input.metadata.name
	not regex.match(`^[a-z0-9][a-z0-9\-]{0,61}[a-z0-9]$`, name)
	error := sprintf(
		"Error #7004 - Entity name '%s' must be lowercase kebab-case (letters, numbers, hyphens), 2-63 characters",
		[name],
	)
}

# #7002 — spec must exist (except Location entities which use spec.targets)
deny_missing_spec contains error if {
	not input.spec
	error := sprintf(
		"Error #7002 - Missing 'spec' in %s entity '%s'",
		[input.kind, input.metadata.name],
	)
}

# #7005 — spec.owner is required for all entity types that have spec
deny_missing_owner contains error if {
	input.spec
	not input.spec.owner
	not util_backstage.is_kind("Location")
	error := sprintf(
		"Error #7005 - Missing 'spec.owner' in %s '%s'",
		[input.kind, input.metadata.name],
	)
}
