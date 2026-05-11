package mandatory_all

import data.util_backstage
import rego.v1

# #7005 — spec.owner must be a recognized Echo domain group
deny_invalid_owner contains error if {
	input.spec.owner
	not util_backstage.valid_owner_groups[input.spec.owner]
	error := sprintf(
		"Error #7005 - Invalid 'spec.owner' '%s' in %s '%s'. Owner must be a domain group (e.g. platform, carrier, shipper, data, backoffice)",
		[input.spec.owner, input.kind, input.metadata.name],
	)
}
