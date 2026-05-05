package mandatory_all

import rego.v1

test_deny_api_missing_type if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
spec:
  lifecycle: production
  owner: platform
  definition: "openapi: 3.0.0"
  `)
	count(deny_api_missing_type) > 0 with input as cfg
}

test_deny_api_missing_lifecycle if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
spec:
  type: openapi
  owner: platform
  definition: "openapi: 3.0.0"
  `)
	count(deny_api_missing_lifecycle) > 0 with input as cfg
}

test_deny_api_missing_definition if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
spec:
  type: openapi
  lifecycle: production
  owner: platform
  `)
	count(deny_api_missing_definition) > 0 with input as cfg
}

test_deny_api_invalid_lifecycle if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
spec:
  type: openapi
  lifecycle: active
  owner: platform
  definition: "openapi: 3.0.0"
  `)
	count(deny_api_invalid_lifecycle) > 0 with input as cfg
}

test_allow_valid_api if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
spec:
  type: openapi
  lifecycle: production
  owner: platform
  definition: "openapi: 3.0.0"
  `)
	count(deny_api_missing_type) == 0 with input as cfg
	count(deny_api_missing_lifecycle) == 0 with input as cfg
	count(deny_api_missing_definition) == 0 with input as cfg
	count(deny_api_invalid_lifecycle) == 0 with input as cfg
}

test_allow_component_without_definition if {
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
	count(deny_api_missing_definition) == 0 with input as cfg
}
