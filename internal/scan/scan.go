package scan

import (
	"fmt"
	"path/filepath"
	"sort"
)

func Scan(dir string) (any, error) {
	absDir, err := filepath.Abs(dir)
	if err != nil {
		return nil, fmt.Errorf("resolve path: %w", err)
	}

	goFiles := findGoFiles(absDir)
	if len(goFiles) > 0 {
		return scanPackage(dir, absDir, goFiles)
	}

	packageDirs := findPackageDirs(absDir)
	if len(packageDirs) == 0 {
		return nil, fmt.Errorf("no Go packages in %s", dir)
	}

	return scanPackages(dir, packageDirs)
}

func scanPackage(dir, absDir string, goFiles []string) (*PackageInventory, error) {
	files, pkgName := parseGoFiles(goFiles)
	if len(files) == 0 {
		return nil, fmt.Errorf("no Go files in %s", dir)
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Name < files[j].Name
	})

	return &PackageInventory{
		Package: pkgName,
		Path:    dir,
		Files:   files,
	}, nil
}

func scanPackages(dir string, packageDirs []string) (*MultiPackageInventory, error) {
	var packages []PackageInventory
	for _, absSubDir := range packageDirs {
		goFiles := findGoFiles(absSubDir)
		relDir := filepath.Join(dir, filepath.Base(absSubDir))
		pkg, err := scanPackage(relDir, absSubDir, goFiles)
		if err != nil {
			continue
		}
		packages = append(packages, *pkg)
	}

	if len(packages) == 0 {
		return nil, fmt.Errorf("no Go packages in subdirectories of %s", dir)
	}

	sort.Slice(packages, func(i, j int) bool {
		return packages[i].Path < packages[j].Path
	})

	return &MultiPackageInventory{Packages: packages}, nil
}
