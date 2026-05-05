package mandatory_all

import rego.v1

test_deny_location_missing_targets if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: test-repo
spec: {}
  `)
	count(deny_location_missing_targets) > 0 with input as cfg
}

test_deny_location_empty_targets if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: test-repo
spec:
  targets: []
  `)
	count(deny_location_empty_targets) > 0 with input as cfg
}

test_allow_location_with_targets if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: test-repo
spec:
  targets:
    - ./test-system/**/*.yaml
  `)
	count(deny_location_missing_targets) == 0 with input as cfg
	count(deny_location_empty_targets) == 0 with input as cfg
}

test_allow_non_location_without_targets if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_location_missing_targets) == 0 with input as cfg
}
