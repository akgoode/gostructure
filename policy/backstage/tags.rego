package mandatory_all

import rego.v1

# Backstage tag format: sequences of [a-z0-9+#] separated by [-], max 63 chars
# This catches real production errors like "redis-7.1" and "v1.0" which contain dots
deny_invalid_tag contains error if {
	some i, tag in input.metadata.tags
	not regex.match(`^[a-z0-9+#]+(-[a-z0-9+#]+)*$`, tag)
	error := sprintf(
		"Error #7006 - Tag '%s' (tags.%d) in %s '%s' is not valid. Tags must be sequences of [a-z0-9+#] separated by hyphens",
		[tag, i, input.kind, input.metadata.name],
	)
}

deny_tag_too_long contains error if {
	some i, tag in input.metadata.tags
	count(tag) > 63
	error := sprintf(
		"Error #7006 - Tag '%s' (tags.%d) in %s '%s' exceeds 63 character limit (%d chars)",
		[tag, i, input.kind, input.metadata.name, count(tag)],
	)
}
