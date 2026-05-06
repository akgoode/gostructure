package mandatory_all

import rego.v1

# --- Component missing type ---

test_deny_component_missing_type if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  lifecycle: production
  owner: platform
  `)
	count(deny_component_missing_type) > 0 with input as cfg
}

test_allow_component_with_type if {
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
	count(deny_component_missing_type) == 0 with input as cfg
}

# --- Component missing lifecycle ---

test_deny_component_missing_lifecycle if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  owner: platform
  `)
	count(deny_component_missing_lifecycle) > 0 with input as cfg
}

# --- Component invalid type ---

test_deny_component_invalid_type if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: microservice
  lifecycle: production
  owner: platform
  `)
	count(deny_component_invalid_type) > 0 with input as cfg
}

test_allow_component_valid_types if {
	types := ["service", "website", "library", "app", "api", "documentation"]
	every t in types {
		cfg := parse_config("yaml", sprintf(`
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: %s
  lifecycle: production
  owner: platform
`, [t]))
		count(deny_component_invalid_type) == 0 with input as cfg
	}
}

# --- Component invalid lifecycle ---

test_deny_component_invalid_lifecycle if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: active
  owner: platform
  `)
	count(deny_component_invalid_lifecycle) > 0 with input as cfg
}

# --- Non-Component entities should not trigger Component rules ---

test_allow_system_without_type if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: test-system
spec:
  owner: platform
  `)
	count(deny_component_missing_type) == 0 with input as cfg
	count(deny_component_missing_lifecycle) == 0 with input as cfg
}
