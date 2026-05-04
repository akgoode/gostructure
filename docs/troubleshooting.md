# Code Structure Analyzer — Troubleshooting

## Common Issues

### "no Go files found" or "no Go packages found"

**Symptom:** `code-structure go <dir>` returns an error.

**Cause:** The scanner has strict depth behavior:
- It looks for `.go` files in the target directory first
- If none found, it looks one level of subdirectories
- It does **not** recurse deeper

**Fix:** Point the scanner at the actual package directory, not a parent:

```bash
# Wrong — if pkg/ has subdirectories but no .go files at root
code-structure go ./pkg

# Right — point at the specific package
code-structure go ./pkg/orders

# Right — or point at a directory whose immediate children are packages
code-structure go ./internal
```

### "dotnet-scanner not found"

**Symptom:** `code-structure dotnet` fails with a binary-not-found error.

**Cause:** The companion .NET binary hasn't been built or isn't in the expected location.

**Fix:**

```bash
# Build the .NET scanner
make build-dotnet
# Or: dotnet publish tools/dotnet-scanner -c Release -o ./bin/dotnet-scanner

# Option A: Move it next to the code-structure binary
cp bin/dotnet-scanner/dotnet-scanner ./dotnet-scanner

# Option B: Set the environment variable
export CODESTRUCTURE_DOTNET_SCANNER=$(pwd)/bin/dotnet-scanner/dotnet-scanner
```

### "CODESTRUCTURE_DOTNET_SCANNER set but file not found"

**Symptom:** The env var is set but the path doesn't exist.

**Fix:** Verify the path is correct and the binary exists:

```bash
ls -la "$CODESTRUCTURE_DOTNET_SCANNER"
# If missing, rebuild: make build-dotnet
```

### Conftest shows no output

**Symptom:** Piping to conftest produces no violations or warnings when you expected some.

**Possible causes:**

1. **Wrong policy path** — make sure `-p policy/go` (or `dotnet`) points to the actual directory
2. **Missing `-`** — conftest needs `-` at the end to read from stdin
3. **Wrong input shape** — the `packages.rego` rules expect `input.packages` (multi-package scan), not `input.files` (single package scan). If you scanned a single package, the package-level rules won't fire.

```bash
# Verify the scanner output is valid JSON
code-structure go ./internal/goscan | python3 -m json.tool

# Verify conftest can read the policies
conftest verify -p policy/go
```

### Warnings not showing up

**Symptom:** Only violations appear; warnings are silent.

**Cause:** Conftest only shows warnings in certain output modes.

**Fix:** Use `--no-fail` to see warnings alongside violations:

```bash
code-structure go ./pkg/myservice | conftest test -p policy/go --no-fail -
```

### "make build" succeeds but dotnet-scanner not built

**Symptom:** `make build` completes without error but `bin/dotnet-scanner/` doesn't exist.

**Cause:** The .NET SDK is not installed. The Makefile runs `dotnet publish` which silently fails if `dotnet` isn't available (Make doesn't abort unless you use `-e` or `set -e`).

**Fix:** Install the .NET 8.0 SDK:

```bash
# macOS
brew install dotnet@8

# Verify
dotnet --version
```

## Policy Test Failures

### Specific policy directories not tested

The default `make test-policies` only tests `policy/go/` and `policy/dotnet/`. The HTTP Server and Worker policy tests must be run separately:

```bash
conftest verify -p policy/http-server
conftest verify -p policy/worker
```

### Writing new policy tests

Rego test files follow the naming convention `*_test.rego` and live alongside the policy files they test. Use `conftest verify -p policy/<category>` to run them.

## Getting Help

- [Conftest documentation](https://www.conftest.dev/)
- [OPA Rego reference](https://www.openpolicyagent.org/docs/latest/policy-reference/)
- Repository: [Echo-Global-Logistics-Inc/code-structure](https://github.com/Echo-Global-Logistics-Inc/code-structure)
