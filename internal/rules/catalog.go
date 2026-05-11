package rules

var order = []string{
	"GO-CFG-001",
	"GO-CFG-002",
	"GO-ERR-001",
	"GO-IMP-001",
	"GO-IMP-002",
	"GO-PKG-001",
	"GO-PKG-002",
	"GO-PKG-003",
	"GO-STRUCT-001",
	"GO-STRUCT-002",
	"GO-STRUCT-003",
	"GO-STRUCT-004",
	"GO-STRUCT-005",
	"GO-STRUCT-006",
	"GO-STRUCT-007",
	"GO-STRUCT-008",
	"GO-TEST-001",
	"GO-TEST-002",
	"GO-TEST-003",
	"GO-LAY-001",
	"GO-LAY-002",
	"GO-LAY-003",
}

var catalog = map[string]Rule{
	// --- Configuration ---

	"GO-CFG-001": {
		ID:          "GO-CFG-001",
		Severity:    "error",
		Category:    "config",
		Title:       "Missing Config struct",
		Description: "Packages with a constructor (New*) must export a Config struct. The caller builds it from env vars, flags, or hardcoded values in tests. The package never reaches outward for configuration.",
	},
	"GO-CFG-002": {
		ID:          "GO-CFG-002",
		Severity:    "error",
		Category:    "config",
		Title:       "Constructor does not accept Config",
		Description: "When both a Config struct and constructor exist, the constructor must accept Config as a parameter. Signature: New(cfg Config) (*T, error).",
	},

	// --- Error handling ---

	"GO-ERR-001": {
		ID:          "GO-ERR-001",
		Severity:    "error",
		Category:    "errors",
		Title:       "Missing domain error types",
		Description: "Packages with exported functions that return error must define domain error types — either sentinel errors (var ErrNotFound) or custom error types (type ValidationError struct).",
	},

	// --- Imports ---

	"GO-IMP-001": {
		ID:          "GO-IMP-001",
		Severity:    "error",
		Category:    "imports",
		Title:       "Test package in production code",
		Description: "Test frameworks (testify, gomock) must not be imported in non-test files.",
	},
	"GO-IMP-002": {
		ID:          "GO-IMP-002",
		Severity:    "warning",
		Category:    "imports",
		Title:       "Too many imports",
		Description: "Files importing more than 8 packages are pulling in too many concerns.",
		Rationale:   "Each import is a dependency on someone else's API, behavior, and release cycle. A file that imports both database drivers and HTTP routers is doing two jobs.",
		Exceptions:  "Composition roots (main.go, wire.go) legitimately import many packages to assemble the dependency graph. Entry points that register routes or configure middleware will naturally have high import counts.",
		Judgment:     "Check whether the file is a composition root or entry point. If so, this is expected. If it's a domain file, look for import clusters that suggest the file should be split.",
	},

	// --- Packages ---

	"GO-PKG-001": {
		ID:          "GO-PKG-001",
		Severity:    "error",
		Category:    "packages",
		Title:       "Layer-named package",
		Description: "Packages named after technical layers (handlers, services, repositories, utils) group code by role instead of by domain. Name packages after what they do.",
	},
	"GO-PKG-002": {
		ID:          "GO-PKG-002",
		Severity:    "error",
		Category:    "packages",
		Title:       "Package has no exported functions",
		Description: "Every package must export at least one function. A package with no public API is dead code or misplaced internal logic.",
	},
	"GO-PKG-003": {
		ID:          "GO-PKG-003",
		Severity:    "warning",
		Category:    "packages",
		Title:       "Too many packages in module",
		Description: "Modules with more than 10 packages may have over-decomposed.",
		Rationale:   "Each package is a compilation unit and an API boundary. Too many thin packages create navigation overhead and often indicate premature abstraction.",
		Exceptions:  "Modules with genuinely distinct domains (e.g., a monorepo with orders, billing, auth) will naturally exceed this. The threshold assumes a single-domain service.",
		Judgment:     "Count how many packages have real business logic vs. how many are thin wrappers or type-only packages. If most are substantial, the count is justified.",
	},

	// --- Structure ---

	"GO-STRUCT-001": {
		ID:          "GO-STRUCT-001",
		Severity:    "error",
		Category:    "structure",
		Title:       "No global mutable variables",
		Description: "Package-level vars create hidden coupling and race conditions. Use const, move to function scope, or return from constructor. Exempt: error sentinels (Err*) and throwaway (_).",
	},
	"GO-STRUCT-002": {
		ID:          "GO-STRUCT-002",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Interface too large",
		Description: "Interfaces with more than 5 methods create tight coupling.",
		Rationale:   "Every implementation must satisfy every method, and every consumer depends on methods it doesn't call. In tests, you mock methods you don't exercise. The Go standard library's most powerful interfaces are 1-3 methods.",
		Exceptions:  "Thin CRUD services where the consumer's method count is proportional to the interface size — each handler delegates to 1-3 interface methods, and the service uses all interface methods across its handlers. The interface is large because the service legitimately covers many operations, not because the interface is poorly scoped.",
		Judgment:     "Compare the interface method count to the consuming struct's method count. If they're proportional (e.g., 11-method interface on a 12-method service) and each service method is a short delegation, the interface is justified. If the consumer only uses a fraction of the methods, split into consumer-specific slices.",
	},
	"GO-STRUCT-003": {
		ID:          "GO-STRUCT-003",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Too many functions in file",
		Description: "Files with more than 10 non-test functions are doing too many things.",
		Rationale:   "Each file should represent one concept. Large files make it hard to find what you're looking for and tend to accumulate unrelated responsibilities.",
		Exceptions:  "Files that define a type and all its methods will naturally have many functions if the type has a broad API. A file with 12 methods on one receiver is more cohesive than a file with 8 unrelated free functions.",
		Judgment:     "Check whether the functions share a receiver or form a pipeline. If they all serve one type, the file is cohesive despite the count. If they're unrelated free functions, split by concept.",
	},
	"GO-STRUCT-004": {
		ID:          "GO-STRUCT-004",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Too many function parameters",
		Description: "Functions with more than 4 parameters are hard to call correctly and test exhaustively.",
		Rationale:   "The combinatorial state space grows with each parameter. Callers have to remember argument order. Named fields in a struct are self-documenting.",
		Exceptions:  "Constructors that accept multiple dependencies via dependency injection. If each parameter is a distinct interface (not data), grouping them into a config struct may obscure the dependency graph rather than clarify it.",
		Judgment:     "Check whether the parameters are data (strings, ints, options) or dependencies (interfaces). Data parameters that travel together should become a struct. Dependency parameters in a constructor are often fine as-is if each is a distinct concern.",
	},
	"GO-STRUCT-005": {
		ID:          "GO-STRUCT-005",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Too many return values",
		Description: "Functions returning more than 2 values force callers to juggle multiple results.",
		Rationale:   "Go convention is (result, error). Beyond that, the function is computing multiple things and the caller destructures them all. Named return types in a struct are self-documenting.",
		Exceptions:  "Repository list methods that return (items, totalCount, hasMore, error) are a common pattern where each value serves a distinct pagination purpose. Wrapping them in a struct is fine but not always worth the abstraction.",
		Judgment:     "If the extra returns are pagination metadata (count, hasMore, cursor), the pattern is well-understood and widely used. If they're unrelated values, wrap in a struct.",
	},
	"GO-STRUCT-006": {
		ID:          "GO-STRUCT-006",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Struct has too many fields",
		Description: "Structs with more than 8 fields represent too many concepts. Config structs are exempt.",
		Rationale:   "Each field multiplies the state space. Large structs tend to accumulate unrelated responsibilities. Look for fields that cluster together.",
		Exceptions:  "Service structs that hold many injected dependencies. If each field is a distinct interface dependency, the struct is a composition root for that service — the field count reflects the service's integration surface, not poor cohesion.",
		Judgment:     "Check whether the fields cluster into groups. If you can name the groups (e.g., 'cache dependencies' vs. 'database dependencies'), they should be sub-types. If each field is a distinct dependency with no natural grouping, the count may be inherent to the service's scope.",
	},
	"GO-STRUCT-007": {
		ID:          "GO-STRUCT-007",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Type has too many methods",
		Description: "Types with more than 10 methods accumulate too many responsibilities.",
		Rationale:   "Method clusters that serve different purposes indicate the type is doing too many things. Extract clusters into separate types and delegate.",
		Exceptions:  "CRUD service types that handle create, get, update, delete, list plus a few variants (getByEmail, addRole, etc.). Each method is a thin handler; the type's cohesion comes from operating on one domain entity.",
		Judgment:     "Check whether the methods form distinct clusters (e.g., read operations vs. write operations vs. admin operations). If they do, extract. If every method is a short handler for the same entity, the type is a CRUD facade and the count is proportional to the API surface.",
	},
	"GO-STRUCT-008": {
		ID:          "GO-STRUCT-008",
		Severity:    "warning",
		Category:    "structure",
		Title:       "Exported struct missing constructor",
		Description: "Exported structs with injected dependencies and behavior need a New* constructor to centralize initialization.",
		Rationale:   "Without a constructor, every caller assembles the struct differently. The constructor is the single place that enforces valid initialization. Pure data types (no methods) are exempt.",
		Exceptions:  "Structs that are intentionally assembled by a code generator or framework (e.g., ORM entities, protobuf messages). If the struct's fields are all exported and there are no invariants to enforce, a constructor adds ceremony without value.",
		Judgment:     "Check whether the struct has unexported fields or pointer dependencies. If so, a constructor is needed to enforce valid setup. If all fields are exported value types, the struct is a data type and direct initialization is fine.",
	},

	// --- Testing ---

	"GO-TEST-001": {
		ID:          "GO-TEST-001",
		Severity:    "error",
		Category:    "testing",
		Title:       "Missing test file",
		Description: "Every non-test source file must have a corresponding _test.go file. Use //codestructure:skip-tests to exempt declarative files.",
	},
	"GO-TEST-002": {
		ID:          "GO-TEST-002",
		Severity:    "error",
		Category:    "testing",
		Title:       "Exported function has no test",
		Description: "Every exported top-level function must have a Test<FuncName> test. Respects skip-tests tag.",
	},
	"GO-TEST-003": {
		ID:          "GO-TEST-003",
		Severity:    "error",
		Category:    "testing",
		Title:       "Exported method has no test",
		Description: "Every exported method must have a Test<Receiver>_<Method> test. Respects skip-tests tag.",
	},

	// --- Layout ---

	"GO-LAY-001": {
		ID:          "GO-LAY-001",
		Severity:    "warning",
		Category:    "layout",
		Title:       "shared/ package too large",
		Description: "The shared kernel should stay thin — 6 non-test files max.",
		Rationale:   "Shared packages become a dumping ground for anything that doesn't obviously belong elsewhere. Once they grow, every package depends on them and they're impossible to refactor.",
		Exceptions:  "Projects with a deliberately large shared kernel (middleware, error types, response helpers, auth utilities) where the team has decided to centralize cross-cutting concerns.",
		Judgment:     "Check whether the files in shared/ are genuinely cross-cutting (middleware, error types, response format) or whether domain-specific logic has leaked in. If you can name a domain for any file, it should move to that domain's package.",
	},
	"GO-LAY-002": {
		ID:          "GO-LAY-002",
		Severity:    "warning",
		Category:    "layout",
		Title:       "Domain package missing expected files",
		Description: "Domain packages with a constructor are expected to have service.go and models.go.",
		Rationale:   "Consistent file layout makes navigation predictable. A reader can open any domain package and find the business logic in service.go and the types in models.go.",
		Exceptions:  "Infrastructure packages (database, cache, messaging, middleware) that sit under internal/ but aren't domain packages. They follow their own conventions — a redis package has client.go, not service.go. Also, small packages where the domain logic and types fit in a single file.",
		Judgment:     "Check whether the package is a domain package (business logic) or an infrastructure adapter (wraps an external system). Infrastructure packages should not be expected to follow domain file layout. Also check package size — a 2-file package doesn't need the full layout.",
	},
	"GO-LAY-003": {
		ID:          "GO-LAY-003",
		Severity:    "warning",
		Category:    "layout",
		Title:       "Package outside expected directories",
		Description: "Packages outside cmd/, api/, internal/, gen/, and client/ are importable by other modules.",
		Rationale:   "Code under internal/ is protected from external import. Code outside it becomes part of the module's public API, which constrains refactoring and creates backwards compatibility obligations.",
		Exceptions:  "Standalone scripts, migration runners, or seed tools that are intentionally separate entry points (like a migrations/ or scripts/ directory with main packages). Also, SDK packages in pkg/ for projects that follow that convention.",
		Judgment:     "Check whether the package is a main package (entry point) or a library. Entry points outside the standard directories are fine if they're build targets. Library code should move under internal/ unless it's intentionally exported.",
	},
}
