package mandatory_all

import data.util_backstage
import rego.v1

# #7005 — API must have spec.type
deny_api_missing_type contains error if {
	util_backstage.is_kind("API")
	not input.spec.type
	error := sprintf(
		"Error #7005 - Missing 'spec.type' in API '%s'",
		[input.metadata.name],
	)
}

# #7005 — API must have spec.lifecycle
deny_api_missing_lifecycle contains error if {
	util_backstage.is_kind("API")
	not input.spec.lifecycle
	error := sprintf(
		"Error #7005 - Missing 'spec.lifecycle' in API '%s'",
		[input.metadata.name],
	)
}

# #7005 — API must have spec.definition
deny_api_missing_definition contains error if {
	util_backstage.is_kind("API")
	not input.spec.definition
	error := sprintf(
		"Error #7005 - Missing 'spec.definition' in API '%s'",
		[input.metadata.name],
	)
}

# #7005 — API spec.lifecycle must be valid
deny_api_invalid_lifecycle contains error if {
	util_backstage.is_kind("API")
	input.spec.lifecycle
	not util_backstage.valid_lifecycle_states[input.spec.lifecycle]
	error := sprintf(
		"Error #7005 - Invalid 'spec.lifecycle' '%s' in API '%s'. Expected one of: experimental, development, production, deprecated",
		[input.spec.lifecycle, input.metadata.name],
	)
}
