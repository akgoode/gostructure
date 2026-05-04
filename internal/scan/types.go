package scan

type PackageInventory struct {
	Package string          `json:"package"`
	Path    string          `json:"path"`
	Files   []FileInventory `json:"files"`
}

type MultiPackageInventory struct {
	Packages []PackageInventory `json:"packages"`
}

type FileInventory struct {
	Name    string      `json:"name"`
	IsTest  bool        `json:"is_test"`
	Tags    []string    `json:"tags,omitempty"`
	Imports []string    `json:"imports"`
	Funcs   []FuncDecl  `json:"funcs"`
	Types   []TypeDecl  `json:"types"`
	Vars    []VarDecl   `json:"vars"`
	Consts  []ConstDecl `json:"consts"`
}

type FuncDecl struct {
	Name         string   `json:"name"`
	Receiver     string   `json:"receiver"`
	Exported     bool     `json:"exported"`
	Params       []Field  `json:"params"`
	Returns      []string `json:"returns"`
	ReturnsError bool     `json:"returns_error"`
	Line         int      `json:"line"`
}

type Field struct {
	Name     string `json:"name"`
	Type     string `json:"type"`
	Exported bool   `json:"exported"`
	Tag      string `json:"tag,omitempty"`
}

type TypeDecl struct {
	Name     string   `json:"name"`
	Kind     string   `json:"kind"`
	Exported bool     `json:"exported"`
	Line     int      `json:"line"`
	Fields   []Field  `json:"fields,omitempty"`
	Methods  []string `json:"methods,omitempty"`
}

type VarDecl struct {
	Name     string `json:"name"`
	Type     string `json:"type,omitempty"`
	Exported bool   `json:"exported"`
	Line     int    `json:"line"`
}

type ConstDecl struct {
	Name     string `json:"name"`
	Type     string `json:"type,omitempty"`
	Exported bool   `json:"exported"`
	Line     int    `json:"line"`
}
