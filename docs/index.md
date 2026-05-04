# Code Structure Analyzer — Overview

The **code-structure** tool scans Go packages and .NET assemblies into structural JSON inventories, then validates them against OPA/Conftest policy rules that enforce Echo's code conventions. It is the machine-readable layer beneath the Platform team's code structure standards — the scanner extracts facts, and the policies decide what those facts mean.

| | |
|---|---|
| **Owner** | Domain Platform |
| **Lifecycle** | Experimental |
| **Languages** | Go 1.26, C# .NET 8.0, Rego |
| **Repository** | [Echo-Global-Logistics-Inc/code-structure](https://github.com/Echo-Global-Logistics-Inc/code-structure) |

## How It Works

The tool implements a two-stage pipeline:

1. **Scan** — `code-structure go <dir>` or `code-structure dotnet <assembly.dll>` produces a JSON inventory of the code's structure (packages, files, types, functions, imports, tags).
2. **Validate** — pipe the JSON into `conftest test -p policy/<language>` to evaluate it against OPA policy rules. Violations appear as conftest failures; warnings appear as advisory messages.

```bash
# Go: scan and validate
code-structure go ./pkg/orders | conftest test -p policy/go --no-fail -

# .NET: scan and validate
code-structure dotnet ./bin/Release/net8.0/Echo.Orders.Api.dll | conftest test -p policy/dotnet --no-fail -
```

## Policy Categories

The tool ships with four policy categories, each targeting a different concern:

| Category | Path | Target | Rules |
|----------|------|--------|-------|
| **Go** | `policy/go/` | Go packages | Config, errors, imports, packages, structure, testing |
| **.NET** | `policy/dotnet/` | .NET assemblies | Config, errors, namespaces, structure |
| **HTTP Server** | `policy/http-server/` | Go HTTP servers | Required constructor, routes, health check |
| **Worker** | `policy/worker/` | Go workers | Required constructor, RunOnce |

The Go and .NET categories are general-purpose — run them on any codebase. The HTTP Server and Worker categories are opt-in overlays applied when validating specific service types.

## Quick Start

```bash
# Build everything
make build

# Run Go scanner
./code-structure go ./internal/goscan

# Run .NET scanner (requires dotnet-scanner binary)
./code-structure dotnet ./path/to/Assembly.dll

# Run all tests
make test
```

See [Local Development](local-setup.md) for full setup instructions and [CLI Reference](cli-reference.md) for command details.
