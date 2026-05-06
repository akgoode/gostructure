package mandatory_all

import rego.v1

# --- apiVersion ---

test_deny_missing_api_version if {
	cfg := parse_config("yaml", `
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_api_version) > 0 with input as cfg
}

test_deny_invalid_api_version if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1beta1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_invalid_api_version) > 0 with input as cfg
}

test_allow_valid_api_version if {
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
	count(deny_missing_api_version) == 0 with input as cfg
	count(deny_invalid_api_version) == 0 with input as cfg
}

# --- kind ---

test_deny_missing_kind if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
metadata:
  name: test-service
spec:
  owner: platform
  `)
	count(deny_missing_kind) > 0 with input as cfg
}

test_deny_invalid_kind if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Deployment
metadata:
  name: test-service
spec:
  owner: platform
  `)
	count(deny_invalid_kind) > 0 with input as cfg
}

test_allow_valid_kinds if {
	kinds := ["Component", "System", "API", "Resource", "Domain", "Location", "Group", "User"]
	every kind in kinds {
		cfg := parse_config("yaml", sprintf(`
apiVersion: backstage.io/v1alpha1
kind: %s
metadata:
  name: test-entity
spec:
  owner: platform
  targets:
    - ./**/*.yaml
`, [kind]))
		count(deny_missing_kind) == 0 with input as cfg
		count(deny_invalid_kind) == 0 with input as cfg
	}
}

# --- metadata ---

test_deny_missing_metadata if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
spec:
  owner: platform
  `)
	count(deny_missing_metadata) > 0 with input as cfg
}

test_deny_missing_name if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  description: test
spec:
  owner: platform
  `)
	count(deny_missing_name) > 0 with input as cfg
}

test_deny_invalid_name_uppercase if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: MyService
spec:
  owner: platform
  `)
	count(deny_invalid_name) > 0 with input as cfg
}

test_deny_invalid_name_underscores if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my_service
spec:
  owner: platform
  `)
	count(deny_invalid_name) > 0 with input as cfg
}

test_allow_valid_name if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: orders-service
spec:
  owner: platform
  `)
	count(deny_missing_name) == 0 with input as cfg
	count(deny_invalid_name) == 0 with input as cfg
}

# --- spec ---

test_deny_missing_spec if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  `)
	count(deny_missing_spec) > 0 with input as cfg
}

test_deny_missing_owner if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
spec:
  type: service
  `)
	count(deny_missing_owner) > 0 with input as cfg
}

test_allow_location_without_owner if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: test-repo
spec:
  targets:
    - ./**/*.yaml
  `)
	count(deny_missing_owner) == 0 with input as cfg
}
