package main

import rego.v1

deny contains msg if {
	some file in input.files
	not file.is_test
	not "allow-globals" in _file_tags(file)
	some v in file.vars
	v.name != "_"
	not startswith(v.name, "Err")
	msg := sprintf("%s:%d — package-level var '%s': avoid mutable global state. Make this a const, move it inside the function that uses it, or return it from a constructor.", [file.name, v.line, v.name])
}

warn contains msg if {
	some file in input.files
	some t in file.types
	t.kind == "interface"
	count(t.methods) > 5
	msg := sprintf("%s\n%s", [
		sprintf("CONSIDER: %s:%d — interface '%s' has %d methods (max 5)", [file.name, t.line, t.name, count(t.methods)]),
		concat("\n", [
			"",
			"Large interfaces create tight coupling — every implementation must satisfy",
			"every method, and every consumer depends on methods it doesn't call.",
			"",
			"Define interfaces where they're consumed, with only the methods that caller",
			"needs. A function that only reads should depend on a 1-method Reader, not a",
			"6-method Store. This makes testing trivial — mock 1 method, not 6 — and",
			"lets you swap implementations without touching unrelated code.",
			"",
			"Before:",
			"  type Store interface {",
			"      Get(id string) (Order, error)",
			"      List() ([]Order, error)",
			"      Create(Order) error",
			"      Update(Order) error",
			"      Delete(id string) error",
			"      Archive(id string) error",
			"  }",
			"",
			"After — each consumer defines what it needs:",
			"  // in the function that lists orders",
			"  type orderLister interface {",
			"      List() ([]Order, error)",
			"  }",
			"",
			"  // in the function that archives orders",
			"  type orderArchiver interface {",
			"      Get(id string) (Order, error)",
			"      Archive(id string) error",
			"  }",
		]),
	])
}

warn contains msg if {
	some file in input.files
	not file.is_test
	funcs := [f | some f in file.funcs; not startswith(f.name, "Test")]
	count(funcs) > 10
	msg := sprintf("%s\n%s", [
		sprintf("SHOULD: %s — file has %d functions (max 10)", [file.name, count(funcs)]),
		concat("\n", [
			"",
			"A file with this many functions is doing too many things. Each file should",
			"represent one concept or one step in a workflow. When a file grows, it's",
			"usually because unrelated logic has accumulated — not because the concept",
			"is genuinely that large.",
			"",
			"Look for clusters of functions that work together and move them to their",
			"own file named after what they do. The goal is that a reader can find the",
			"right file by guessing its name.",
			"",
			"Signals that functions belong in a separate file:",
			"  - They share a receiver or operate on the same type",
			"  - They form a pipeline (output of one feeds into the next)",
			"  - They're all helpers for one exported function",
			"  - They could be described with a single noun (parsing, validation, auth)",
		]),
	])
}

warn contains msg if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	count(f.params) > 4
	msg := sprintf("%s\n%s", [
		sprintf("SHOULD: %s:%d — %s has %d parameters (max 4)", [file.name, f.line, f.name, count(f.params)]),
		concat("\n", [
			"",
			"Beyond 4 parameters, the set of possible input combinations fans out",
			"exponentially. Each new parameter multiplies the state space — making the",
			"function harder to reason about, harder to test exhaustively, and harder",
			"to call correctly. Four is the threshold where humans (and agents) stop",
			"being able to hold all the combinations in their head.",
			"",
			"Group parameters that belong together into a named struct. If they travel",
			"as a set, they're a concept that deserves a name. A struct also makes the",
			"function easier to test — construct one value instead of a long argument",
			"list — and easier to extend without changing every call site.",
			"",
			"Before:",
			"  func Execute(boardID string, cardID string, timeout time.Duration,",
			"      model string, prompt string, logDir string) error",
			"",
			"After:",
			"  type ExecParams struct {",
			"      BoardID string",
			"      CardID  string",
			"      Timeout time.Duration",
			"      Model   string",
			"      Prompt  string",
			"      LogDir  string",
			"  }",
			"",
			"  func Execute(params ExecParams) error",
		]),
	])
}

warn contains msg if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	count(f.returns) > 2
	msg := sprintf("%s\n%s", [
		sprintf("SHOULD: %s:%d — %s returns %d values (max 2)", [file.name, f.line, f.name, count(f.returns)]),
		concat("\n", [
			"",
			"Go functions conventionally return at most two values: a result and an",
			"error. Beyond that, the function is computing multiple things at once and",
			"the caller has to juggle them all — often discarding values it doesn't need.",
			"",
			"When a function needs to return more than two values, group them into a",
			"struct. This gives the return values a name, makes them self-documenting,",
			"and lets you add fields later without changing the function signature.",
			"",
			"Before:",
			"  func Process(id string) (string, int, bool, error)",
			"",
			"After:",
			"  type Result struct {",
			"      Name    string",
			"      Count   int",
			"      Success bool",
			"  }",
			"",
			"  func Process(id string) (Result, error)",
		]),
	])
}

warn contains msg if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
	t.name != "Config"
	count(t.fields) > 8
	msg := sprintf("%s\n%s", [
		sprintf("SHOULD: %s:%d — struct '%s' has %d fields (max 8)", [file.name, t.line, t.name, count(t.fields)]),
		concat("\n", [
			"",
			"A struct with this many fields is representing too many concepts at once.",
			"Like a function with too many parameters, each field multiplies the state",
			"space — more combinations to construct, more fields to keep consistent,",
			"more surface area to test.",
			"",
			"Look for fields that cluster together and extract them into their own type.",
			"If a subset of fields is always read or written as a group, that group is",
			"a concept that deserves its own name.",
			"",
			"Before:",
			"  type Order struct {",
			"      ID, CustomerID, Status string",
			"      BillingStreet, BillingCity, BillingState, BillingZip string",
			"      ShippingStreet, ShippingCity, ShippingState, ShippingZip string",
			"  }",
			"",
			"After:",
			"  type Address struct {",
			"      Street, City, State, Zip string",
			"  }",
			"",
			"  type Order struct {",
			"      ID, CustomerID, Status string",
			"      Billing  Address",
			"      Shipping Address",
			"  }",
			"",
			"Note: Config structs are exempt — they are flat by design because each",
			"field maps to one external input (env var, flag, secret).",
		]),
	])
}

_method_count(receiver) := count([f |
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.receiver == receiver
])

_type_receivers contains t.name if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
}

warn contains msg if {
	some receiver in _type_receivers
	mc := _method_count(receiver)
	mc > 10
	msg := sprintf("%s\n%s", [
		sprintf("CONSIDER: type '%s' has %d methods (max 10)", [receiver, mc]),
		concat("\n", [
			"",
			"A type with this many methods is accumulating too many responsibilities.",
			"It becomes the place where everything happens — hard to understand, hard",
			"to test in isolation, and hard to reuse parts of without dragging in the",
			"whole thing.",
			"",
			"Look for method clusters that serve different purposes. A type that handles",
			"both data access and business logic should be two types. A type that manages",
			"both configuration and execution is two concepts sharing a struct.",
			"",
			"Split by extracting a group of methods and the fields they use into a new",
			"type. The original type can hold the new one as a field and delegate.",
			"",
			"Before:",
			"  type Worker struct { ... }",
			"  func (w *Worker) FetchCards() { ... }",
			"  func (w *Worker) FilterCards() { ... }",
			"  func (w *Worker) PickCard() { ... }",
			"  func (w *Worker) Execute() { ... }",
			"  func (w *Worker) RecordResult() { ... }",
			"  func (w *Worker) SendNotification() { ... }",
			"  // ... 5 more methods",
			"",
			"After:",
			"  type CardPicker struct { ... }",
			"  func (p *CardPicker) Pick(cards []Card) Card { ... }",
			"",
			"  type Worker struct {",
			"      picker CardPicker",
			"      // ...",
			"  }",
		]),
	])
}

warn contains msg if {
	some file in input.files
	not file.is_test
	some t in file.types
	t.kind == "struct"
	t.exported
	t.name != "Config"
	_has_fields_needing_setup(t)
	not _has_constructor_for(t.name)
	msg := sprintf("%s\n%s", [
		sprintf("SHOULD: %s:%d — exported struct '%s' has no constructor", [file.name, t.line, t.name]),
		concat("\n", [
			"",
			"This struct is exported and has fields that suggest it needs wiring —",
			"interfaces, pointers, or external types that the caller would have to",
			"know how to set up correctly. Without a constructor, every caller",
			"assembles the struct by hand, which spreads initialization logic and",
			"makes it easy to forget a required field.",
			"",
			"Add a New function that validates inputs and returns the struct ready",
			"to use. The constructor is the single place that knows what a valid",
			"instance looks like.",
			"",
			"Example:",
			"  func New(cfg Config) (*Server, error) {",
			"      if cfg.Port == 0 {",
			"          return nil, errors.New(\"port is required\")",
			"      }",
			"      return &Server{",
			"          port:   cfg.Port,",
			"          logger: cfg.Logger,",
			"      }, nil",
			"  }",
		]),
	])
}

_has_fields_needing_setup(t) if {
	some f in t.fields
	startswith(f.type, "*")
}

_has_fields_needing_setup(t) if {
	some f in t.fields
	contains(f.type, ".")
}

_has_fields_needing_setup(t) if {
	some f in t.fields
	not f.exported
}

_has_constructor_for(type_name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name == "New"
}

_has_constructor_for(type_name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.receiver == ""
	f.name == concat("", ["New", type_name])
}

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
