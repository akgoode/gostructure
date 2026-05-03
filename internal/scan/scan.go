package scan

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"sort"
	"strings"
)

func Package(dir string) (*PackageInventory, error) {
	absDir, err := filepath.Abs(dir)
	if err != nil {
		return nil, fmt.Errorf("resolve path: %w", err)
	}

	fset := token.NewFileSet()
	pkgs, err := parser.ParseDir(fset, absDir, nil, 0)
	if err != nil {
		return nil, fmt.Errorf("parse package: %w", err)
	}
	if len(pkgs) == 0 {
		return nil, fmt.Errorf("no Go packages in %s", dir)
	}

	name, files := collectFiles(fset, pkgs)

	return &PackageInventory{
		Package: name,
		Path:    dir,
		Files:   files,
	}, nil
}

func collectFiles(fset *token.FileSet, pkgs map[string]*ast.Package) (string, []FileInventory) {
	var pkgName string
	var files []FileInventory

	for name, pkg := range pkgs {
		if !strings.HasSuffix(name, "_test") {
			pkgName = name
		}
		for filePath, file := range pkg.Files {
			files = append(files, inventoryFile(fset, filepath.Base(filePath), file))
		}
	}

	if pkgName == "" {
		for name := range pkgs {
			pkgName = strings.TrimSuffix(name, "_test")
			break
		}
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Name < files[j].Name
	})

	return pkgName, files
}
