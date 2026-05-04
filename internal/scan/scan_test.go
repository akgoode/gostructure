package scan

import (
	"os"
	"path/filepath"
	"testing"
)

func writeFile(t *testing.T, dir, name, content string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, name), []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestScan_SinglePackage(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "math.go", `package math

func Add(a, b int) int { return a + b }
func Sub(a, b int) int { return a - b }
`)
	writeFile(t, dir, "math_test.go", `package math

import "testing"

func TestAdd(t *testing.T) {}
func TestSub(t *testing.T) {}
`)

	result, err := Scan(dir)
	if err != nil {
		t.Fatalf("Scan: %v", err)
	}
	inv, ok := result.(*PackageInventory)
	if !ok {
		t.Fatalf("expected *PackageInventory, got %T", result)
	}
	if inv.Package != "math" {
		t.Errorf("Package = %q, want math", inv.Package)
	}
	if len(inv.Files) != 2 {
		t.Fatalf("got %d files, want 2", len(inv.Files))
	}

	src := inv.Files[0]
	if src.Name != "math.go" {
		t.Errorf("Files[0].Name = %q", src.Name)
	}
	if src.IsTest {
		t.Error("Files[0] should not be test")
	}
	if len(src.Funcs) != 2 {
		t.Errorf("got %d funcs, want 2", len(src.Funcs))
	}

	test := inv.Files[1]
	if !test.IsTest {
		t.Error("Files[1] should be test")
	}
}

func TestScan_MultiPackage(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "alpha"), "alpha.go", `package alpha

func Run() {}
`)
	writeFile(t, filepath.Join(dir, "beta"), "beta.go", `package beta

func Start() error { return nil }
`)

	result, err := Scan(dir)
	if err != nil {
		t.Fatalf("Scan: %v", err)
	}
	inv, ok := result.(*MultiPackageInventory)
	if !ok {
		t.Fatalf("expected *MultiPackageInventory, got %T", result)
	}
	if len(inv.Packages) != 2 {
		t.Fatalf("got %d packages, want 2", len(inv.Packages))
	}

	a := inv.Packages[0]
	if a.Package != "alpha" {
		t.Errorf("Packages[0].Package = %q, want alpha", a.Package)
	}

	b := inv.Packages[1]
	if b.Package != "beta" {
		t.Errorf("Packages[1].Package = %q, want beta", b.Package)
	}
	if len(b.Files[0].Funcs) != 1 || !b.Files[0].Funcs[0].ReturnsError {
		t.Errorf("beta func = %+v", b.Files[0].Funcs)
	}
}

func TestScan_Tags(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "gen.go", `//gostructure:skip-tests
//gostructure:allow-globals
package gen

var Registry = map[string]int{}

func Lookup(key string) int { return Registry[key] }
`)

	result, err := Scan(dir)
	if err != nil {
		t.Fatalf("Scan: %v", err)
	}
	inv := result.(*PackageInventory)
	file := inv.Files[0]
	if len(file.Tags) != 2 {
		t.Fatalf("Tags = %v, want 2 tags", file.Tags)
	}
	if file.Tags[0] != "skip-tests" || file.Tags[1] != "allow-globals" {
		t.Errorf("Tags = %v", file.Tags)
	}
}

func TestScan_ExternalTestPackage(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "lib.go", `package lib

func Hello() string { return "hi" }
`)
	writeFile(t, dir, "lib_test.go", `package lib_test

import "testing"

func TestHello(t *testing.T) {}
`)

	result, err := Scan(dir)
	if err != nil {
		t.Fatalf("Scan: %v", err)
	}
	inv := result.(*PackageInventory)
	if inv.Package != "lib" {
		t.Errorf("Package = %q, want lib", inv.Package)
	}
	if len(inv.Files) != 2 {
		t.Fatalf("got %d files, want 2", len(inv.Files))
	}
}

func TestFindGoFiles(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "main.go", "package main\n")
	writeFile(t, dir, "README.md", "# readme\n")

	files := findGoFiles(dir)
	if len(files) != 1 {
		t.Fatalf("got %d files, want 1", len(files))
	}
}

func TestFindPackageDirs(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "foo"), "foo.go", "package foo\n")
	writeFile(t, filepath.Join(dir, "bar"), "bar.go", "package bar\n")
	writeFile(t, filepath.Join(dir, "empty"), ".gitkeep", "")

	dirs := findPackageDirs(dir)
	if len(dirs) != 2 {
		t.Fatalf("got %d dirs, want 2", len(dirs))
	}
}

func TestScan_EmptyDir(t *testing.T) {
	dir := t.TempDir()
	_, err := Scan(dir)
	if err == nil {
		t.Fatal("expected error for empty dir")
	}
}
