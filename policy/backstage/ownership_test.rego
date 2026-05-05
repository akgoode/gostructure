package mandatory_all

import rego.v1

test_deny_invalid_owner if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: johns-team
  `)
	count(deny_invalid_owner) > 0 with input as cfg
}

test_allow_valid_domain_owners if {
	owners := ["platform", "carrier", "shipper", "data", "backoffice", "echo-it", "domain_platform", "team_developer_platform"]
	every owner in owners {
		cfg := parse_config("yaml", sprintf(`
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: %s
`, [owner]))
		count(deny_invalid_owner) == 0 with input as cfg
	}
}
