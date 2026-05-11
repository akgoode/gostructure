# Code Structure Analyzer — Policy Catalog

Complete catalog of all OPA/Conftest policy rules shipped with code-structure. Rules use two severity levels:

- **Error** (`violation_*` rules) — structural problems that must be fixed; conftest treats these as failures
- **Warning** (`warn` rules) — suggestions worth considering; conftest prints them but exits zero

## Go Policies (`policy/go/package/`)

### Configuration (`config.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-CFG-001 | error | Missing Config struct | Packages with a constructor (`New*`) must export a `Config` struct declaring their dependencies. The caller builds it; the package never reaches outward for configuration. |
| GO-CFG-002 | error | Constructor does not accept Config | When both a `Config` struct and constructor exist, the constructor must accept `Config` as a parameter. Signature: `New(cfg Config) (*T, error)`. |

### Error Handling (`errors.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-ERR-001 | error | Missing domain error types | Packages with exported functions that return error must define domain error types — either sentinel errors (`var ErrNotFound = errors.New(...)`) or custom error types (`type ValidationError struct`). |

### Imports (`imports.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| — | warning | Too many imports | Files importing more than 8 packages are pulling in too many concerns. Split the file along import clusters. |
| GO-IMP-001 | error | Test package in production code | Test frameworks (testify, gomock) must not be imported in non-test files. They become runtime dependencies and confuse the boundary between test and production code. |

### Packages (`packages.rego`)

Applies to `MultiPackageInventory` input (multi-package scans).

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-PKG-001 | error | Layer-named package | Packages named after technical layers (`handlers`, `services`, `repositories`, `utils`, `helpers`, `common`, etc.) group code by role instead of by domain. Name packages after what they do. |
| GO-PKG-002 | error | Package has no exported functions | Every package must export at least one function. A package with no public API is dead code. |
| — | warning | Too many packages in module | Modules with more than 10 packages may have over-decomposed. Consider consolidating. |

### Structure (`structure.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-STRUCT-001 | error | No global mutable variables | Package-level vars create hidden coupling and race conditions. Exempt: error sentinels (`Err*`), blank identifiers (`_`), and files tagged `allow-globals`. |
| — | warning | Interface too large | Interfaces with more than 5 methods create tight coupling. Define interfaces where consumed. |
| — | warning | Too many functions in file | Files with more than 10 non-test functions are doing too many things. Split by concept. |
| — | warning | Too many function parameters | Beyond 4 parameters, group into a named struct. |
| — | warning | Too many return values | Beyond 2 return values, wrap in a struct. |
| — | warning | Struct has too many fields | Structs with more than 8 fields (Config structs exempt). Extract field clusters. |
| — | warning | Type has too many methods | Types with more than 10 methods. Extract method clusters into separate types. |
| — | warning | Exported struct missing constructor | Exported structs with complex fields (pointers, external types, unexported fields) need a `New*` constructor. Config structs exempt. |

### Testing (`testing.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-TEST-001 | error | Missing test file | Every non-test source file (except `doc.go`, `main.go`) must have a corresponding `_test.go` file. Use the `skip-tests` tag to exempt declarative files. |
| GO-TEST-002 | error | Exported function has no test | Every exported top-level function must have a `Test<FuncName>` test function. Respects the `skip-tests` tag. |
| GO-TEST-003 | error | Exported method has no test | Every exported method must have a `Test<Receiver>_<Method>` test function. Respects the `skip-tests` tag. |

## .NET Policies (`policy/dotnet/`)

### Configuration (`config.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| NET-CFG-001 | error | Service class missing Options type | Service classes with constructor injection should have a corresponding `*Options` class for configuration. |
| NET-CFG-002 | error | Constructor takes concrete types instead of interfaces | Constructor parameters (excluding primitives, Options, ILogger, and framework types) should be interfaces. Concrete dependencies violate dependency inversion. |

### Error Handling (`errors.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| NET-ERR-001 | error | Missing domain exception types | Namespaces with public service classes should define custom exception types. Throw `OrderNotFoundException`, not `InvalidOperationException` with a magic string. |

### Namespaces (`namespaces.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| NET-NS-001 | error | Layer-named namespace segment | Namespaces with terminal segments named after technical layers (`Services`, `Repositories`, `Helpers`, `Utils`, `Controllers`, `Models`, etc.). Name namespaces after what they do. |
| NET-NS-002 | error | Namespace has no public types | Every namespace should have at least one public type. |
| — | warning | Too many namespaces in assembly | Assemblies with more than 15 namespaces. Consider consolidating. |

### Structure (`structure.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| NET-STRUCT-001 | error | No public static mutable fields | Public static fields that are neither readonly nor const create shared mutable state. Make the field readonly, const, or encapsulate behind a property. |
| — | warning | Interface too large | Interfaces with more than 5 public methods. Split into consumer-specific interfaces. |
| — | warning | Too many public methods on type | Classes with more than 15 public methods (excluding overrides). Extract method clusters. |
| — | warning | Too many method parameters | Beyond 4 parameters, group into a request object. |
| — | warning | Too many constructor parameters | Constructors with more than 6 parameters. Extract dependency clusters. |
| — | warning | Too many fields on type | Classes with more than 8 fields (Options/Config/Settings exempt). Extract field clusters. |
| — | warning | Prefer sealed classes | Public non-abstract classes that are not sealed. Seal by default. Exception types and Options/Config/Settings classes exempt. |

## Go App Layout Policies (`policy/go/app/`)

Project-wide layout rules that validate folder structure. Run against the full project tree with `code-structure go .`.

### Layout (`layout.rego`)

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| — | warning | shared/ package too large | Packages under `shared/` with more than 6 non-test files. Move domain-specific logic into its own package. |
| — | warning | Domain package missing expected files | Top-level domain packages under `internal/` (excluding `shared/`) with a constructor should have `service.go`, `models.go`, and `handler.go` or `worker.go`. Sub-packages within a domain are exempt. |

## HTTP Server Policies (`policy/http-server/`)

Opt-in overlay for Go HTTP server packages. Apply with `-p policy/http-server` in addition to `-p policy/go`.

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-HTTP-001 | error | Missing HTTP server constructor | Must export `New(cfg Config) (*Server, error)` or `NewServer(...)`. |
| GO-HTTP-002 | error | Missing Routes function | Must export `Routes()` as a flat table of contents for all endpoints. |
| GO-HTTP-003 | error | Missing Health function | Must export `Health()` for Kubernetes readiness/liveness probes. |

## Worker Policies (`policy/worker/`)

Opt-in overlay for Go worker packages. Apply with `-p policy/worker` in addition to `-p policy/go`.

| Rule ID | Severity | Title | Description |
|---------|----------|-------|-------------|
| GO-WORK-001 | error | Missing worker constructor | Must export `New(cfg Config) (*Worker, error)` or `NewWorker(...)`. |
| GO-WORK-002 | error | Missing RunOnce function | Must export `RunOnce(ctx context.Context) error` — a single idempotent execution cycle. |

## Testing Policies

Policy rules themselves are tested with `conftest verify`. The Makefile runs:

```bash
conftest verify -p policy/go
conftest verify -p policy/go/app
conftest verify -p policy/dotnet
```

**Note:** The `http-server/` and `worker/` policy directories are NOT included in `make test-policies`. To verify them separately:

```bash
conftest verify -p policy/http-server
conftest verify -p policy/worker
```
