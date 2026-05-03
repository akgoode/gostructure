package scan

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
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
	pkgs, err := parser.ParseDir(fset, absDir, nil, parser.ParseComments)
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

func IsMultiPackage(dir string) (bool, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return false, fmt.Errorf("read dir: %w", err)
	}
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".go") {
			return false, nil
		}
	}
	for _, e := range entries {
		if e.IsDir() {
			sub := filepath.Join(dir, e.Name())
			subEntries, err := os.ReadDir(sub)
			if err != nil {
				continue
			}
			for _, se := range subEntries {
				if !se.IsDir() && strings.HasSuffix(se.Name(), ".go") {
					return true, nil
				}
			}
		}
	}
	return false, nil
}

func Packages(dir string) (*MultiPackageInventory, error) {
	absDir, err := filepath.Abs(dir)
	if err != nil {
		return nil, fmt.Errorf("resolve path: %w", err)
	}

	var pkgs []PackageInventory
	entries, err := os.ReadDir(absDir)
	if err != nil {
		return nil, fmt.Errorf("read dir: %w", err)
	}

	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		sub := filepath.Join(absDir, e.Name())
		hasGo := false
		subEntries, err := os.ReadDir(sub)
		if err != nil {
			continue
		}
		for _, se := range subEntries {
			if !se.IsDir() && strings.HasSuffix(se.Name(), ".go") {
				hasGo = true
				break
			}
		}
		if !hasGo {
			continue
		}

		inv, err := Package(filepath.Join(dir, e.Name()))
		if err != nil {
			continue
		}
		pkgs = append(pkgs, *inv)
	}

	if len(pkgs) == 0 {
		return nil, fmt.Errorf("no Go packages in subdirectories of %s", dir)
	}

	sort.Slice(pkgs, func(i, j int) bool {
		return pkgs[i].Path < pkgs[j].Path
	})

	return &MultiPackageInventory{Packages: pkgs}, nil
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
