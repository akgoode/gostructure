package scan

type PackageInventory struct {
	Package string          `json:"package"`
	Path    string          `json:"path"`
	Files   []FileInventory `json:"files"`
}

type FileInventory struct {
	Name    string      `json:"name"`
	IsTest  bool        `json:"is_test"`
	Imports []string    `json:"imports"`
	Funcs   []FuncDecl  `json:"funcs"`
	Types   []TypeDecl  `json:"types"`
	Vars    []VarDecl   `json:"vars"`
	Consts  []ConstDecl `json:"consts"`
}

type FuncDecl struct {
	Name     string `json:"name"`
	Receiver string `json:"receiver"`
	Exported bool   `json:"exported"`
	Line     int    `json:"line"`
}

type TypeDecl struct {
	Name     string   `json:"name"`
	Kind     string   `json:"kind"`
	Exported bool     `json:"exported"`
	Line     int      `json:"line"`
	Methods  []string `json:"methods,omitempty"`
}

type VarDecl struct {
	Name     string `json:"name"`
	Exported bool   `json:"exported"`
	Line     int    `json:"line"`
}

type ConstDecl struct {
	Name     string `json:"name"`
	Exported bool   `json:"exported"`
	Line     int    `json:"line"`
}
