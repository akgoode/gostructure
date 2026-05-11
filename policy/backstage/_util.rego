package util_backstage

import rego.v1

valid_kinds := {
	"Component",
	"System",
	"API",
	"Resource",
	"Domain",
	"Location",
	"Group",
	"User",
}

valid_component_types := {
	"service",
	"website",
	"library",
	"app",
	"api",
	"documentation",
}

valid_api_types := {
	"openapi",
	"asyncapi",
	"grpc",
	"lambda-authorizer",
}

valid_resource_types := {
	"database",
	"s3-bucket",
	"sqs-queue",
	"dynamodb-table",
	"kafka-topic",
	"documentdb",
	"opensearch",
	"elasticache",
	"msk-cluster",
}

valid_lifecycle_states := {
	"experimental",
	"development",
	"production",
	"deprecated",
}

# Echo domain groups that can own entities
valid_owner_groups := {
	"backoffice",
	"carrier",
	"data",
	"domain_backoffice",
	"domain_carrier",
	"domain_data",
	"domain_integrations",
	"domain_platform",
	"domain_shipper",
	"echo-it",
	"integrations-echo-sync",
	"platform",
	"shipper",
	"team_developer_platform",
}

has_annotation(annotation) if {
	input.metadata.annotations[annotation]
}

annotation_value(annotation) := input.metadata.annotations[annotation]

is_kind(kind) if {
	input.kind == kind
}
