# Code Structure Analyzer — CLI Reference

## Commands

### `code-structure go <directory>`

Scans Go packages in the target directory into a structural JSON inventory.

**Scan Depth Behavior:**

- If `<directory>` contains `.go` files directly → scans that single package, returns a `PackageInventory`
- If `<directory>` has no `.go` files but has subdirectories with `.go` files → scans one level of subdirectories, returns a `MultiPackageInventory`
- Does **not** recurse deeper than one level of subdirectories
- Returns an error if no Go files are found at either level

```bash
# Single package
code-structure go ./internal/goscan
# Output: PackageInventory (flat object)

# Multiple packages (directory of packages)
code-structure go ./internal
# Output: MultiPackageInventory (array wrapper)
```

### `code-structure dotnet <assembly.dll>`

Scans a compiled .NET assembly into a structural JSON inventory using reflection.

Requires the `dotnet-scanner` companion binary. See [Local Development](local-setup.md) for build instructions.

```bash
code-structure dotnet ./bin/Release/net8.0/Echo.Orders.Api.dll
# Output: AssemblyInventory
```

## JSON Output Schemas

### Go: PackageInventory (single package)

Returned when the target directory contains `.go` files directly.

```json
{
  "package": "goscan",
  "path": "./internal/goscan",
  "files": [
    {
      "name": "scan.go",
      "is_test": false,
      "tags": [],
      "imports": ["errors", "fmt", "path/filepath", "sort"],
      "funcs": [
        {
          "name": "Scan",
          "receiver": "",
          "exported": true,
          "params": [{"name": "dir", "type": "string"}],
          "returns": ["any", "error"],
          "returns_error": true,
          "line": 15
        }
      ],
      "types": [
        {
          "name": "PackageInventory",
          "kind": "struct",
          "exported": true,
          "line": 4,
          "fields": [
            {"name": "Package", "type": "string", "exported": true, "tag": "json:\"package\""},
            {"name": "Path", "type": "string", "exported": true, "tag": "json:\"path\""},
            {"name": "Files", "type": "[]FileInventory", "exported": true, "tag": "json:\"files\""}
          ]
        }
      ],
      "vars": [],
      "consts": []
    }
  ]
}
```

### Go: MultiPackageInventory (multiple packages)

Returned when the target directory has subdirectories containing `.go` files.

```json
{
  "packages": [
    {
      "package": "goscan",
      "path": "./internal/goscan",
      "files": [...]
    },
    {
      "package": "dotnetscan",
      "path": "./internal/dotnetscan",
      "files": [...]
    }
  ]
}
```

### .NET: AssemblyInventory

```json
{
  "assembly": "Echo.Orders.Api",
  "path": "./bin/Release/net8.0/Echo.Orders.Api.dll",
  "namespaces": [
    {
      "namespace": "Echo.Orders.Api",
      "types": [
        {
          "name": "OrderService",
          "kind": "class",
          "is_public": true,
          "is_abstract": false,
          "is_sealed": false,
          "is_static": false,
          "base_type": null,
          "interfaces": ["IOrderService"],
          "attributes": [],
          "constructors": [
            {
              "is_public": true,
              "parameters": [
                {"name": "repository", "type": "IOrderRepository"},
                {"name": "options", "type": "IOptions<OrderServiceOptions>"}
              ]
            }
          ],
          "methods": [
            {
              "name": "CreateOrder",
              "is_public": true,
              "is_static": false,
              "is_virtual": false,
              "is_override": false,
              "parameters": [{"name": "request", "type": "CreateOrderRequest"}],
              "return_type": "Task<Order>",
              "attributes": []
            }
          ],
          "properties": [
            {
              "name": "Name",
              "type": "string",
              "is_public": true,
              "has_getter": true,
              "has_setter": false
            }
          ],
          "fields": [],
          "tags": []
        }
      ]
    }
  ]
}
```

## File Tags

The Go scanner recognizes `//codestructure:<tag>` comments anywhere in a Go source file. Tags are extracted into the `tags` array in the file inventory and can be used by policies to exempt individual files from specific rules.

### Syntax

```go
//codestructure:skip-tests
//codestructure:allow-globals
package mypackage
```

Tags must appear as standalone comments (not inline). Multiple tags can be placed on separate lines.

### Known Tags

| Tag | Effect | Used By |
|-----|--------|---------|
| `skip-tests` | Exempts the file from test coverage rules (GO-TEST-001, GO-TEST-002, GO-TEST-003) | `policy/go/testing.rego` |
| `allow-globals` | Exempts the file from the no-global-variables rule (GO-STRUCT-001) | `policy/go/structure.rego` |

### Writing Custom Tags

Policy authors can define new tags by reading the `file.tags` array in Rego:

```rego
# Check if a file has a specific tag
not "my-custom-tag" in file.tags
```

Tags are arbitrary strings — any `//codestructure:` comment becomes a tag. Policies decide what they mean.

## Piping to Conftest

The code-structure CLI outputs JSON to stdout. Pipe it into conftest to evaluate policies:

```bash
# Go — general policies
code-structure go ./pkg/myservice | conftest test -p policy/go --no-fail -

# Go — HTTP server overlay (combine with general policies)
code-structure go ./pkg/myservice | conftest test -p policy/go -p policy/http-server --no-fail -

# Go — worker overlay
code-structure go ./pkg/myworker | conftest test -p policy/go -p policy/worker --no-fail -

# .NET — general policies
code-structure dotnet ./bin/MyService.dll | conftest test -p policy/dotnet --no-fail -
```

The `-` at the end tells conftest to read from stdin. The `--no-fail` flag prevents non-zero exit on warnings (violations still cause failures).

### Combining Policy Categories

The HTTP Server and Worker policies are **overlays** — they add requirements on top of the base Go policies. Use multiple `-p` flags to combine them:

```bash
# Validate as an HTTP server
code-structure go ./pkg/api | conftest test -p policy/go -p policy/http-server -

# Validate as a worker
code-structure go ./pkg/consumer | conftest test -p policy/go -p policy/worker -
```
