package dotnetscan

type AssemblyInventory struct {
	Assembly   string               `json:"assembly"`
	Path       string               `json:"path"`
	Namespaces []NamespaceInventory `json:"namespaces"`
}

type NamespaceInventory struct {
	Namespace string          `json:"namespace"`
	Types     []TypeInventory `json:"types"`
}

type TypeInventory struct {
	Name              string            `json:"name"`
	Kind              string            `json:"kind"`
	IsPublic          bool              `json:"is_public"`
	IsAbstract        bool              `json:"is_abstract"`
	IsSealed          bool              `json:"is_sealed"`
	IsStatic          bool              `json:"is_static"`
	BaseType          *string           `json:"base_type"`
	Interfaces        []string          `json:"interfaces"`
	Attributes        []string          `json:"attributes"`
	GenericParameters []string          `json:"generic_parameters,omitempty"`
	Constructors      []ConstructorDecl `json:"constructors"`
	Methods           []MethodDecl      `json:"methods"`
	Properties        []PropertyDecl    `json:"properties"`
	Fields            []FieldDecl       `json:"fields"`
	NestedTypes       []string          `json:"nested_types,omitempty"`
	Tags              []string          `json:"tags,omitempty"`
}

type ConstructorDecl struct {
	IsPublic   bool        `json:"is_public"`
	Parameters []ParamDecl `json:"parameters"`
}

type MethodDecl struct {
	Name       string      `json:"name"`
	IsPublic   bool        `json:"is_public"`
	IsStatic   bool        `json:"is_static"`
	IsVirtual  bool        `json:"is_virtual"`
	IsOverride bool        `json:"is_override"`
	Parameters []ParamDecl `json:"parameters"`
	ReturnType string      `json:"return_type"`
	Attributes []string    `json:"attributes"`
}

type ParamDecl struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

type PropertyDecl struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	IsPublic  bool   `json:"is_public"`
	HasGetter bool   `json:"has_getter"`
	HasSetter bool   `json:"has_setter"`
}

type FieldDecl struct {
	Name       string `json:"name"`
	Type       string `json:"type"`
	IsPublic   bool   `json:"is_public"`
	IsStatic   bool   `json:"is_static"`
	IsReadonly bool   `json:"is_readonly"`
}
