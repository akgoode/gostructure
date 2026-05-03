package scan

import (
	"go/ast"
	"go/token"
	"strings"
)

func inventoryFile(fset *token.FileSet, name string, file *ast.File) FileInventory {
	return FileInventory{
		Name:    name,
		IsTest:  strings.HasSuffix(name, "_test.go"),
		Imports: extractImports(file),
		Funcs:   extractFuncs(fset, file),
		Types:   extractTypes(fset, file),
		Vars:    extractVars(fset, file),
		Consts:  extractConsts(fset, file),
	}
}

func extractImports(file *ast.File) []string {
	var imports []string
	for _, imp := range file.Imports {
		path := strings.Trim(imp.Path.Value, `"`)
		imports = append(imports, path)
	}
	return imports
}

func extractFuncs(fset *token.FileSet, file *ast.File) []FuncDecl {
	var funcs []FuncDecl
	for _, decl := range file.Decls {
		fn, ok := decl.(*ast.FuncDecl)
		if !ok {
			continue
		}
		f := FuncDecl{
			Name:         fn.Name.Name,
			Exported:     fn.Name.IsExported(),
			ReturnsError: returnsError(fn),
			Line:         fset.Position(fn.Pos()).Line,
		}
		if fn.Recv != nil && len(fn.Recv.List) > 0 {
			f.Receiver = receiverName(fn.Recv.List[0].Type)
		}
		funcs = append(funcs, f)
	}
	return funcs
}

func extractTypes(fset *token.FileSet, file *ast.File) []TypeDecl {
	var types []TypeDecl
	for _, decl := range file.Decls {
		gd, ok := decl.(*ast.GenDecl)
		if !ok || gd.Tok != token.TYPE {
			continue
		}
		for _, spec := range gd.Specs {
			ts := spec.(*ast.TypeSpec)
			td := TypeDecl{
				Name:     ts.Name.Name,
				Exported: ts.Name.IsExported(),
				Line:     fset.Position(ts.Pos()).Line,
			}
			switch t := ts.Type.(type) {
			case *ast.StructType:
				td.Kind = "struct"
			case *ast.InterfaceType:
				td.Kind = "interface"
				td.Methods = interfaceMethods(t)
			default:
				td.Kind = "alias"
			}
			types = append(types, td)
		}
	}
	return types
}

func extractVars(fset *token.FileSet, file *ast.File) []VarDecl {
	var vars []VarDecl
	for _, decl := range file.Decls {
		gd, ok := decl.(*ast.GenDecl)
		if !ok || gd.Tok != token.VAR {
			continue
		}
		for _, spec := range gd.Specs {
			vs := spec.(*ast.ValueSpec)
			for _, name := range vs.Names {
				vars = append(vars, VarDecl{
					Name:     name.Name,
					Exported: name.IsExported(),
					Line:     fset.Position(name.Pos()).Line,
				})
			}
		}
	}
	return vars
}

func extractConsts(fset *token.FileSet, file *ast.File) []ConstDecl {
	var consts []ConstDecl
	for _, decl := range file.Decls {
		gd, ok := decl.(*ast.GenDecl)
		if !ok || gd.Tok != token.CONST {
			continue
		}
		for _, spec := range gd.Specs {
			vs := spec.(*ast.ValueSpec)
			for _, name := range vs.Names {
				consts = append(consts, ConstDecl{
					Name:     name.Name,
					Exported: name.IsExported(),
					Line:     fset.Position(name.Pos()).Line,
				})
			}
		}
	}
	return consts
}

func receiverName(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.StarExpr:
		return receiverName(t.X)
	case *ast.Ident:
		return t.Name
	default:
		return ""
	}
}

func returnsError(fn *ast.FuncDecl) bool {
	if fn.Type.Results == nil {
		return false
	}
	fields := fn.Type.Results.List
	if len(fields) == 0 {
		return false
	}
	last := fields[len(fields)-1]
	ident, ok := last.Type.(*ast.Ident)
	return ok && ident.Name == "error"
}

func interfaceMethods(iface *ast.InterfaceType) []string {
	var methods []string
	for _, field := range iface.Methods.List {
		for _, name := range field.Names {
			methods = append(methods, name.Name)
		}
	}
	return methods
}
