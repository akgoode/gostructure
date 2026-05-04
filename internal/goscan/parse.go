package goscan

import (
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"strings"
)

func parseGoFiles(paths []string) ([]FileInventory, string) {
	fset := token.NewFileSet()
	var files []FileInventory
	var pkgName string

	for _, path := range paths {
		file, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			continue
		}
		if name := file.Name.Name; !strings.HasSuffix(name, "_test") {
			pkgName = name
		}
		files = append(files, inventoryFile(fset, filepath.Base(path), file))
	}

	if pkgName == "" && len(files) > 0 {
		pkgName = strings.TrimSuffix(files[0].Name, "_test.go")
	}

	return files, pkgName
}

func inventoryFile(fset *token.FileSet, name string, file *ast.File) FileInventory {
	return FileInventory{
		Name:    name,
		IsTest:  strings.HasSuffix(name, "_test.go"),
		Tags:    extractTags(file),
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
			Params:       extractParams(fn.Type.Params),
			Returns:      extractReturns(fn.Type.Results),
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

func extractParams(fields *ast.FieldList) []Field {
	if fields == nil {
		return nil
	}
	var params []Field
	for _, field := range fields.List {
		typeName := typeString(field.Type)
		if len(field.Names) == 0 {
			params = append(params, Field{Type: typeName})
			continue
		}
		for _, name := range field.Names {
			params = append(params, Field{
				Name: name.Name,
				Type: typeName,
			})
		}
	}
	return params
}

func extractReturns(fields *ast.FieldList) []string {
	if fields == nil {
		return nil
	}
	var returns []string
	for _, field := range fields.List {
		typeName := typeString(field.Type)
		count := len(field.Names)
		if count == 0 {
			count = 1
		}
		for range count {
			returns = append(returns, typeName)
		}
	}
	return returns
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
				td.Fields = extractStructFields(t)
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
			var typeName string
			if vs.Type != nil {
				typeName = typeString(vs.Type)
			}
			for _, name := range vs.Names {
				vars = append(vars, VarDecl{
					Name:     name.Name,
					Type:     typeName,
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
			var typeName string
			if vs.Type != nil {
				typeName = typeString(vs.Type)
			}
			for _, name := range vs.Names {
				consts = append(consts, ConstDecl{
					Name:     name.Name,
					Type:     typeName,
					Exported: name.IsExported(),
					Line:     fset.Position(name.Pos()).Line,
				})
			}
		}
	}
	return consts
}

func extractStructFields(s *ast.StructType) []Field {
	if s.Fields == nil {
		return nil
	}
	var fields []Field
	for _, f := range s.Fields.List {
		typeName := typeString(f.Type)
		var tag string
		if f.Tag != nil {
			tag = strings.Trim(f.Tag.Value, "`")
		}
		if len(f.Names) == 0 {
			fields = append(fields, Field{
				Type:     typeName,
				Exported: ast.IsExported(typeName),
				Tag:      tag,
			})
			continue
		}
		for _, name := range f.Names {
			fields = append(fields, Field{
				Name:     name.Name,
				Type:     typeName,
				Exported: name.IsExported(),
				Tag:      tag,
			})
		}
	}
	return fields
}

func typeString(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.Ident:
		return t.Name
	case *ast.StarExpr:
		return "*" + typeString(t.X)
	case *ast.SelectorExpr:
		return typeString(t.X) + "." + t.Sel.Name
	case *ast.ArrayType:
		if t.Len == nil {
			return "[]" + typeString(t.Elt)
		}
		return "[...]" + typeString(t.Elt)
	case *ast.MapType:
		return "map[" + typeString(t.Key) + "]" + typeString(t.Value)
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.ChanType:
		return "chan " + typeString(t.Value)
	case *ast.FuncType:
		return "func"
	case *ast.Ellipsis:
		return "..." + typeString(t.Elt)
	default:
		return "unknown"
	}
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

const tagPrefix = "//codestructure:"

func extractTags(file *ast.File) []string {
	var tags []string
	for _, cg := range file.Comments {
		for _, c := range cg.List {
			text := strings.TrimSpace(c.Text)
			if strings.HasPrefix(text, tagPrefix) {
				tag := strings.TrimPrefix(text, tagPrefix)
				tag = strings.TrimSpace(tag)
				if tag != "" {
					tags = append(tags, tag)
				}
			}
		}
	}
	return tags
}
