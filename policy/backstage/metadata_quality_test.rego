package best_practices_all

import rego.v1

# --- description ---

test_deny_missing_description if {
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
	count(deny_missing_description) > 0 with input as cfg
}

test_deny_short_description if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: Too short
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_short_description) > 0 with input as cfg
}

test_allow_good_description if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: This is a service that processes orders and manages fulfillment
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_description) == 0 with input as cfg
	count(deny_short_description) == 0 with input as cfg
}

# --- tags ---

test_deny_missing_tags if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: A service that processes orders
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_tags) > 0 with input as cfg
}

test_deny_empty_tags if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: A service that processes orders
  tags: []
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_empty_tags) > 0 with input as cfg
}

test_allow_with_tags if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: A service that processes orders
  tags:
    - dotnet
    - rest
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_tags) == 0 with input as cfg
	count(deny_empty_tags) == 0 with input as cfg
}

# --- title ---

test_deny_missing_title if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  description: A service that processes orders
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_title) > 0 with input as cfg
}

test_allow_with_title if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  title: Test Service
  description: A service that processes orders
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_title) == 0 with input as cfg
}

# --- Component missing system ---

test_deny_component_missing_system if {
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
	count(deny_component_missing_system) > 0 with input as cfg
}

test_allow_component_with_system if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  system: orders
  `)
	count(deny_component_missing_system) == 0 with input as cfg
}

# --- System missing domain ---

test_deny_system_missing_domain if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: test-system
spec:
  owner: platform
  `)
	count(deny_system_missing_domain) > 0 with input as cfg
}

test_allow_system_with_domain if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: test-system
spec:
  owner: platform
  domain: platform
  `)
	count(deny_system_missing_domain) == 0 with input as cfg
}
