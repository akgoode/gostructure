package mandatory_all

import rego.v1

test_deny_component_missing_annotations if {
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
	count(deny_missing_annotations) > 0 with input as cfg
}

test_allow_component_with_annotations if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  annotations:
    dev.azure.com/project-repo: SharedServices/test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_annotations) == 0 with input as cfg
}

test_allow_system_without_annotations if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: test-system
spec:
  owner: platform
  `)
	count(deny_missing_annotations) == 0 with input as cfg
}

test_deny_component_missing_source_annotation if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  annotations:
    backstage.io/techdocs-ref: url:https://example.com
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_source_annotation) > 0 with input as cfg
}

test_allow_component_with_ado_source if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  annotations:
    dev.azure.com/project-repo: SharedServices/test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_source_annotation) == 0 with input as cfg
}

test_allow_component_with_github_source if {
	cfg := parse_config("yaml", `
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: test-service
  annotations:
    github.com/project-slug: Echo-Global-Logistics-Inc/test-service
spec:
  type: service
  lifecycle: production
  owner: platform
  `)
	count(deny_missing_source_annotation) == 0 with input as cfg
}
