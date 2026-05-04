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
		sprintf("%s:%d — interface '%s' has %d methods (max 5)", [file.name, t.line, t.name, count(t.methods)]),
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
		sprintf("%s — file has %d functions (max 10)", [file.name, count(funcs)]),
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
		sprintf("%s:%d — %s has %d parameters (max 4)", [file.name, f.line, f.name, count(f.params)]),
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

_file_tags(file) := file.tags if {
	file.tags
}

_file_tags(file) := [] if {
	not file.tags
}
