package mandatory_all

import rego.v1

# Links must have absolute URLs (https:// or http://)
# Relative paths like "/docs/default/system/..." cause catalog processing failures
deny_link_relative_url contains error if {
	some i, link in input.metadata.links
	link.url
	not startswith(link.url, "http://")
	not startswith(link.url, "https://")
	error := sprintf(
		"Error #7007 - Link URL '%s' (links.%d) in %s '%s' is not a valid absolute URL. Use https://... not relative paths",
		[link.url, i, input.kind, input.metadata.name],
	)
}

# Links must have a url field
deny_link_missing_url contains error if {
	some i, link in input.metadata.links
	not link.url
	error := sprintf(
		"Error #7007 - Link at index %d in %s '%s' is missing required 'url' field",
		[i, input.kind, input.metadata.name],
	)
}
