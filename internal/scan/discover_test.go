package scan

import (
	"path/filepath"
	"testing"
)

func TestFindGoFiles(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "main.go", "package main\n")
	writeFile(t, dir, "README.md", "# readme\n")

	files, err := findGoFiles(dir)
	if err != nil {
		t.Fatalf("findGoFiles: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("got %d files, want 1", len(files))
	}
}

func TestFindPackageDirs(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "foo"), "foo.go", "package foo\n")
	writeFile(t, filepath.Join(dir, "bar"), "bar.go", "package bar\n")
	writeFile(t, filepath.Join(dir, "empty"), ".gitkeep", "")

	dirs, err := findPackageDirs(dir)
	if err != nil {
		t.Fatalf("findPackageDirs: %v", err)
	}
	if len(dirs) != 2 {
		t.Fatalf("got %d dirs, want 2", len(dirs))
	}
}
