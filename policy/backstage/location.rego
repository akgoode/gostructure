package mandatory_all

import data.util_backstage
import rego.v1

# Location must have spec.targets
deny_location_missing_targets contains error if {
	util_backstage.is_kind("Location")
	not input.spec.targets
	error := sprintf(
		"Error #7005 - Missing 'spec.targets' in Location '%s'. Location entities must declare target globs",
		[input.metadata.name],
	)
}

# Location spec.targets must be a non-empty list
deny_location_empty_targets contains error if {
	util_backstage.is_kind("Location")
	input.spec.targets
	count(input.spec.targets) == 0
	error := sprintf(
		"Error #7005 - Empty 'spec.targets' in Location '%s'. At least one target glob is required",
		[input.metadata.name],
	)
}
