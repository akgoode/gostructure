package mandatory_all

import rego.v1

# Real production failure from backstage-backend logs
test_deny_link_relative_path if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: edi-processor
  links:
    - url: https://dev.azure.com/echo-it/example
      title: Source Code
    - url: /docs/default/system/edi-processor/
      title: Documentation
spec:
  owner: platform
  `)
	count(deny_link_relative_url) > 0 with input as cfg
}

test_deny_link_missing_url if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: test-resource
  links:
    - title: Missing URL
spec:
  type: database
  owner: platform
  `)
	count(deny_link_missing_url) > 0 with input as cfg
}

test_allow_valid_links if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  links:
    - url: https://dev.azure.com/echo-it/SharedServices/_git/test-service
      title: Source Code
      icon: code
    - url: https://echo-backstage.example.com/docs/default/component/test-service
      title: Documentation
      icon: docs
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_link_relative_url) == 0 with input as cfg
	count(deny_link_missing_url) == 0 with input as cfg
}

test_allow_entity_without_links if {
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
	count(deny_link_relative_url) == 0 with input as cfg
	count(deny_link_missing_url) == 0 with input as cfg
}
