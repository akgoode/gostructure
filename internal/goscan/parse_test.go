package goscan

import (
	"go/ast"
	"go/parser"
	"go/token"
	"testing"
)

func parseSource(t *testing.T, src string) (*token.FileSet, *ast.File) {
	t.Helper()
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, "test.go", src, parser.ParseComments)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	return fset, file
}

func TestExtractFuncs(t *testing.T) {
	tests := []struct {
		name     string
		src      string
		expected []FuncDecl
	}{
		{
			name: "plain func",
			src:  "package p\nfunc Hello() {}",
			expected: []FuncDecl{
				{Name: "Hello", Exported: true, Line: 2},
			},
		},
		{
			name: "unexported func",
			src:  "package p\nfunc hello() {}",
			expected: []FuncDecl{
				{Name: "hello", Exported: false, Line: 2},
			},
		},
		{
			name: "method with pointer receiver",
			src:  "package p\ntype S struct{}\nfunc (s *S) Do() {}",
			expected: []FuncDecl{
				{Name: "Do", Receiver: "S", Exported: true, Line: 3},
			},
		},
		{
			name: "method with value receiver",
			src:  "package p\ntype S struct{}\nfunc (s S) Do() {}",
			expected: []FuncDecl{
				{Name: "Do", Receiver: "S", Exported: true, Line: 3},
			},
		},
		{
			name: "returns error",
			src:  "package p\nfunc Run() error { return nil }",
			expected: []FuncDecl{
				{Name: "Run", Exported: true, ReturnsError: true, Returns: []string{"error"}, Line: 2},
			},
		},
		{
			name: "returns value and error",
			src:  "package p\nfunc Get() (int, error) { return 0, nil }",
			expected: []FuncDecl{
				{Name: "Get", Exported: true, ReturnsError: true, Returns: []string{"int", "error"}, Line: 2},
			},
		},
		{
			name: "returns non-error",
			src:  "package p\nfunc Count() int { return 0 }",
			expected: []FuncDecl{
				{Name: "Count", Exported: true, ReturnsError: false, Returns: []string{"int"}, Line: 2},
			},
		},
		{
			name: "params and returns",
			src:  "package p\nimport \"context\"\nfunc New(ctx context.Context, cfg Config) (*Server, error) { return nil, nil }",
			expected: []FuncDecl{
				{
					Name: "New", Exported: true, ReturnsError: true, Line: 3,
					Params:  []Field{{Name: "ctx", Type: "context.Context"}, {Name: "cfg", Type: "Config"}},
					Returns: []string{"*Server", "error"},
				},
			},
		},
		{
			name: "variadic params",
			src:  "package p\nfunc Log(msg string, args ...any) {}",
			expected: []FuncDecl{
				{
					Name: "Log", Exported: true, Line: 2,
					Params: []Field{{Name: "msg", Type: "string"}, {Name: "args", Type: "...any"}},
				},
			},
		},
		{
			name: "unnamed params",
			src:  "package p\nfunc Handle(string, int) {}",
			expected: []FuncDecl{
				{
					Name: "Handle", Exported: true, Line: 2,
					Params: []Field{{Type: "string"}, {Type: "int"}},
				},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset, file := parseSource(t, tt.src)
			got := extractFuncs(fset, file)
			if len(got) != len(tt.expected) {
				t.Fatalf("got %d funcs, want %d", len(got), len(tt.expected))
			}
			for i, want := range tt.expected {
				g := got[i]
				if g.Name != want.Name {
					t.Errorf("func[%d].Name = %q, want %q", i, g.Name, want.Name)
				}
				if g.Receiver != want.Receiver {
					t.Errorf("func[%d].Receiver = %q, want %q", i, g.Receiver, want.Receiver)
				}
				if g.Exported != want.Exported {
					t.Errorf("func[%d].Exported = %v, want %v", i, g.Exported, want.Exported)
				}
				if g.ReturnsError != want.ReturnsError {
					t.Errorf("func[%d].ReturnsError = %v, want %v", i, g.ReturnsError, want.ReturnsError)
				}
				if g.Line != want.Line {
					t.Errorf("func[%d].Line = %d, want %d", i, g.Line, want.Line)
				}
				if len(g.Params) != len(want.Params) {
					t.Errorf("func[%d].Params = %v, want %v", i, g.Params, want.Params)
				} else {
					for j, wp := range want.Params {
						if g.Params[j].Name != wp.Name || g.Params[j].Type != wp.Type {
							t.Errorf("func[%d].Params[%d] = %v, want %v", i, j, g.Params[j], wp)
						}
					}
				}
				if len(g.Returns) != len(want.Returns) {
					t.Errorf("func[%d].Returns = %v, want %v", i, g.Returns, want.Returns)
				} else {
					for j, wr := range want.Returns {
						if g.Returns[j] != wr {
							t.Errorf("func[%d].Returns[%d] = %q, want %q", i, j, g.Returns[j], wr)
						}
					}
				}
			}
		})
	}
}

func TestExtractTypes(t *testing.T) {
	tests := []struct {
		name     string
		src      string
		expected []TypeDecl
	}{
		{
			name: "struct with fields",
			src:  "package p\ntype Config struct{\n\tName string\n\tPort int\n\ttimeout float64\n}",
			expected: []TypeDecl{
				{Name: "Config", Kind: "struct", Exported: true, Line: 2, Fields: []Field{
					{Name: "Name", Type: "string", Exported: true},
					{Name: "Port", Type: "int", Exported: true},
					{Name: "timeout", Type: "float64", Exported: false},
				}},
			},
		},
		{
			name: "struct with tags and embedding",
			src:  "package p\nimport \"time\"\ntype Order struct{\n\tID string `json:\"id\"`\n\tCreated time.Time\n}",
			expected: []TypeDecl{
				{Name: "Order", Kind: "struct", Exported: true, Line: 3, Fields: []Field{
					{Name: "ID", Type: "string", Exported: true, Tag: `json:"id"`},
					{Name: "Created", Type: "time.Time", Exported: true},
				}},
			},
		},
		{
			name: "interface with methods",
			src:  "package p\ntype Reader interface {\n\tRead() error\n\tClose() error\n}",
			expected: []TypeDecl{
				{Name: "Reader", Kind: "interface", Exported: true, Line: 2, Methods: []string{"Read", "Close"}},
			},
		},
		{
			name: "type alias",
			src:  "package p\ntype ID string",
			expected: []TypeDecl{
				{Name: "ID", Kind: "alias", Exported: true, Line: 2},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset, file := parseSource(t, tt.src)
			got := extractTypes(fset, file)
			if len(got) != len(tt.expected) {
				t.Fatalf("got %d types, want %d", len(got), len(tt.expected))
			}
			for i, want := range tt.expected {
				g := got[i]
				if g.Name != want.Name {
					t.Errorf("type[%d].Name = %q, want %q", i, g.Name, want.Name)
				}
				if g.Kind != want.Kind {
					t.Errorf("type[%d].Kind = %q, want %q", i, g.Kind, want.Kind)
				}
				if g.Exported != want.Exported {
					t.Errorf("type[%d].Exported = %v, want %v", i, g.Exported, want.Exported)
				}
				if len(g.Methods) != len(want.Methods) {
					t.Errorf("type[%d].Methods = %v, want %v", i, g.Methods, want.Methods)
				} else {
					for j, m := range want.Methods {
						if g.Methods[j] != m {
							t.Errorf("type[%d].Methods[%d] = %q, want %q", i, j, g.Methods[j], m)
						}
					}
				}
				if len(g.Fields) != len(want.Fields) {
					t.Errorf("type[%d].Fields count = %d, want %d", i, len(g.Fields), len(want.Fields))
				} else {
					for j, wf := range want.Fields {
						gf := g.Fields[j]
						if gf.Name != wf.Name || gf.Type != wf.Type || gf.Exported != wf.Exported || gf.Tag != wf.Tag {
							t.Errorf("type[%d].Fields[%d] = %+v, want %+v", i, j, gf, wf)
						}
					}
				}
			}
		})
	}
}

func TestExtractTags(t *testing.T) {
	tests := []struct {
		name     string
		src      string
		expected []string
	}{
		{
			name:     "no tags",
			src:      "package p\n",
			expected: nil,
		},
		{
			name:     "single tag",
			src:      "//codestructure:skip-tests\npackage p\n",
			expected: []string{"skip-tests"},
		},
		{
			name:     "multiple tags",
			src:      "//codestructure:skip-tests\n//codestructure:workflow\npackage p\n",
			expected: []string{"skip-tests", "workflow"},
		},
		{
			name:     "tag with spaces",
			src:      "//codestructure: allow-globals\npackage p\n",
			expected: []string{"allow-globals"},
		},
		{
			name:     "regular comment ignored",
			src:      "// Package p does stuff.\npackage p\n",
			expected: nil,
		},
		{
			name:     "inline comment with tag",
			src:      "package p\nvar x = 1 //codestructure:allow-globals\n",
			expected: []string{"allow-globals"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, file := parseSource(t, tt.src)
			got := extractTags(file)
			if len(got) != len(tt.expected) {
				t.Fatalf("got tags %v, want %v", got, tt.expected)
			}
			for i, want := range tt.expected {
				if got[i] != want {
					t.Errorf("tag[%d] = %q, want %q", i, got[i], want)
				}
			}
		})
	}
}

func TestExtractVars(t *testing.T) {
	src := "package p\nvar (\n\tErrNotFound = errors.New(\"not found\")\n\t_ = 0\n\tglobalState = 1\n)"
	fset, file := parseSource(t, src)
	got := extractVars(fset, file)
	if len(got) != 3 {
		t.Fatalf("got %d vars, want 3", len(got))
	}
	cases := []struct {
		name     string
		exported bool
	}{
		{"ErrNotFound", true},
		{"_", false},
		{"globalState", false},
	}
	for i, want := range cases {
		if got[i].Name != want.name {
			t.Errorf("var[%d].Name = %q, want %q", i, got[i].Name, want.name)
		}
		if got[i].Exported != want.exported {
			t.Errorf("var[%d].Exported = %v, want %v", i, got[i].Exported, want.exported)
		}
	}
}

func TestExtractConsts(t *testing.T) {
	src := "package p\nconst (\n\tMaxRetries = 3\n\tdefaultTimeout = 5\n)"
	fset, file := parseSource(t, src)
	got := extractConsts(fset, file)
	if len(got) != 2 {
		t.Fatalf("got %d consts, want 2", len(got))
	}
	if got[0].Name != "MaxRetries" || !got[0].Exported {
		t.Errorf("const[0] = %+v, want MaxRetries/exported", got[0])
	}
	if got[1].Name != "defaultTimeout" || got[1].Exported {
		t.Errorf("const[1] = %+v, want defaultTimeout/unexported", got[1])
	}
}

func TestInventoryFile(t *testing.T) {
	src := `//codestructure:workflow
package p

import "fmt"

type Server struct{}

func New() *Server { return &Server{} }

func (s *Server) Start() error {
	fmt.Println("starting")
	return nil
}
`
	fset, file := parseSource(t, src)
	inv := inventoryFile(fset, "server.go", file)

	if inv.Name != "server.go" {
		t.Errorf("Name = %q", inv.Name)
	}
	if inv.IsTest {
		t.Error("IsTest should be false")
	}
	if len(inv.Tags) != 1 || inv.Tags[0] != "workflow" {
		t.Errorf("Tags = %v, want [workflow]", inv.Tags)
	}
	if len(inv.Imports) != 1 || inv.Imports[0] != "fmt" {
		t.Errorf("Imports = %v", inv.Imports)
	}
	if len(inv.Types) != 1 || inv.Types[0].Name != "Server" {
		t.Errorf("Types = %v", inv.Types)
	}
	if len(inv.Funcs) != 2 {
		t.Fatalf("got %d funcs, want 2", len(inv.Funcs))
	}
	if inv.Funcs[0].Name != "New" || inv.Funcs[0].Receiver != "" {
		t.Errorf("Funcs[0] = %+v", inv.Funcs[0])
	}
	if inv.Funcs[1].Name != "Start" || inv.Funcs[1].Receiver != "Server" || !inv.Funcs[1].ReturnsError {
		t.Errorf("Funcs[1] = %+v", inv.Funcs[1])
	}
}
