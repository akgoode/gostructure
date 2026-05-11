package mandatory_all

import data.util_backstage
import rego.v1

# #7005 — Component must have spec.type
deny_component_missing_type contains error if {
	util_backstage.is_kind("Component")
	not input.spec.type
	error := sprintf(
		"Error #7005 - Missing 'spec.type' in Component '%s'",
		[input.metadata.name],
	)
}

# #7005 — Component must have spec.lifecycle
deny_component_missing_lifecycle contains error if {
	util_backstage.is_kind("Component")
	not input.spec.lifecycle
	error := sprintf(
		"Error #7005 - Missing 'spec.lifecycle' in Component '%s'",
		[input.metadata.name],
	)
}

# #7005 — Component spec.type must be valid
deny_component_invalid_type contains error if {
	util_backstage.is_kind("Component")
	input.spec.type
	not util_backstage.valid_component_types[input.spec.type]
	error := sprintf(
		"Error #7005 - Invalid 'spec.type' '%s' in Component '%s'. Expected one of: service, website, library, app, api, documentation",
		[input.spec.type, input.metadata.name],
	)
}

# #7005 — Component spec.lifecycle must be valid
deny_component_invalid_lifecycle contains error if {
	util_backstage.is_kind("Component")
	input.spec.lifecycle
	not util_backstage.valid_lifecycle_states[input.spec.lifecycle]
	error := sprintf(
		"Error #7005 - Invalid 'spec.lifecycle' '%s' in Component '%s'. Expected one of: experimental, development, production, deprecated",
		[input.spec.lifecycle, input.metadata.name],
	)
}
