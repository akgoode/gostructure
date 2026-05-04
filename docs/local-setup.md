# Code Structure Analyzer — Local Development

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **Go** | >= 1.21 | Build and run the CLI |
| **.NET SDK** | 8.0 | Build the dotnet-scanner companion binary |
| **Conftest** | any recent | Evaluate OPA policies against scanner output |

All three are required for a full build. The Go scanner works standalone; the .NET scanner requires both Go (for the CLI wrapper) and .NET SDK (for the companion binary).

### Installing Conftest

```bash
# macOS
brew install conftest

# Linux
curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
sudo mv conftest /usr/local/bin/
```

## Building

```bash
# Build everything (Go CLI + .NET scanner)
make build

# Build only the Go CLI
make build-go
# Produces: ./code-structure

# Build only the .NET scanner
make build-dotnet
# Produces: ./bin/dotnet-scanner/dotnet-scanner
```

**Note:** `make build` will fail silently if the .NET SDK is missing — the Go binary will build but the dotnet-scanner won't. If you only need Go scanning, `make build-go` is sufficient.

## Running Tests

```bash
# Run all tests (Go unit tests + Rego policy tests)
make test

# Go unit tests only
make test-go
# Runs: go test ./...

# Rego policy tests only
make test-policies
# Runs: conftest verify -p policy/go && conftest verify -p policy/dotnet
```

**Note:** `make test-policies` only verifies the `go/` and `dotnet/` policy directories. The `http-server/` and `worker/` policies must be verified separately:

```bash
conftest verify -p policy/http-server
conftest verify -p policy/worker
```

## Using the Tool

### Go Scanning

```bash
# Scan a single package
./code-structure go ./internal/goscan

# Scan a directory of packages
./code-structure go ./internal

# Scan and validate with Go policies
./code-structure go ./internal/goscan | conftest test -p policy/go --no-fail -

# Scan and validate with HTTP server overlay
./code-structure go ./pkg/api | conftest test -p policy/go -p policy/http-server -

# Scan and validate with worker overlay
./code-structure go ./pkg/consumer | conftest test -p policy/go -p policy/worker -
```

### .NET Scanning

The .NET scanner requires the `dotnet-scanner` companion binary. The CLI finds it using a 3-step lookup:

1. **`CODESTRUCTURE_DOTNET_SCANNER`** environment variable — if set, uses this as the absolute path to the binary
2. **Sibling binary** — looks for `dotnet-scanner` in the same directory as the `code-structure` executable
3. **`PATH`** — falls back to `PATH` lookup

```bash
# Option 1: Build both to the same directory (sibling resolution)
make build
mv bin/dotnet-scanner/dotnet-scanner ./dotnet-scanner
./code-structure dotnet ./path/to/Assembly.dll

# Option 2: Use environment variable
export CODESTRUCTURE_DOTNET_SCANNER=./bin/dotnet-scanner/dotnet-scanner
./code-structure dotnet ./path/to/Assembly.dll

# Scan and validate with .NET policies
./code-structure dotnet ./path/to/Assembly.dll | conftest test -p policy/dotnet --no-fail -
```

If the binary is not found, the CLI returns an error with build instructions:

```
dotnet-scanner not found: build it with 'dotnet publish tools/dotnet-scanner' or set CODESTRUCTURE_DOTNET_SCANNER
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CODESTRUCTURE_DOTNET_SCANNER` | No | Absolute path to the `dotnet-scanner` binary. Overrides sibling and PATH resolution. Only needed for .NET scanning. |

## Cleaning Up

```bash
make clean
# Removes: code-structure binary, bin/ directory, .NET build artifacts
```
