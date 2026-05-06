package mandatory_all

import rego.v1

# Real production failures from backstage-backend logs
test_deny_tag_with_dots if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: test-elasticache
  tags:
    - elasticache
    - redis
    - caching
    - platform
    - redis-7.1
spec:
  type: elasticache
  owner: platform
  `)
	count(deny_invalid_tag) > 0 with input as cfg
}

test_deny_tag_version_with_dots if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: test-api
  tags:
    - rest
    - openapi
    - dotnet
    - platform
    - api
    - v1.0
spec:
  type: openapi
  lifecycle: production
  owner: platform
  definition: "openapi: 3.0.0"
  `)
	count(deny_invalid_tag) > 0 with input as cfg
}

test_deny_tag_with_uppercase if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  tags:
    - DotNet
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_invalid_tag) > 0 with input as cfg
}

test_allow_valid_tags if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  tags:
    - dotnet
    - rest
    - platform
    - c#
    - kafka+avro
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_invalid_tag) == 0 with input as cfg
}

test_allow_hyphenated_tags if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  tags:
    - echo-sync
    - ado-pipelines
    - api-gateway
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_invalid_tag) == 0 with input as cfg
}
