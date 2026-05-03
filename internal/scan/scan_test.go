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

func TestPackage_Basic(t *testing.T) {
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

	inv, err := Package(dir)
	if err != nil {
		t.Fatalf("Package: %v", err)
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

func TestPackage_Tags(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "gen.go", `//gostructure:skip-tests
//gostructure:allow-globals
package gen

var Registry = map[string]int{}

func Lookup(key string) int { return Registry[key] }
`)

	inv, err := Package(dir)
	if err != nil {
		t.Fatalf("Package: %v", err)
	}
	file := inv.Files[0]
	if len(file.Tags) != 2 {
		t.Fatalf("Tags = %v, want 2 tags", file.Tags)
	}
	if file.Tags[0] != "skip-tests" || file.Tags[1] != "allow-globals" {
		t.Errorf("Tags = %v", file.Tags)
	}
}

func TestIsMultiPackage(t *testing.T) {
	tests := []struct {
		name   string
		setup  func(t *testing.T, dir string)
		expect bool
	}{
		{
			name: "single package with go files",
			setup: func(t *testing.T, dir string) {
				writeFile(t, dir, "main.go", "package main\n")
			},
			expect: false,
		},
		{
			name: "multi package with subdirs",
			setup: func(t *testing.T, dir string) {
				writeFile(t, filepath.Join(dir, "foo"), "foo.go", "package foo\n")
				writeFile(t, filepath.Join(dir, "bar"), "bar.go", "package bar\n")
			},
			expect: true,
		},
		{
			name: "empty dir",
			setup: func(t *testing.T, dir string) {
			},
			expect: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dir := t.TempDir()
			tt.setup(t, dir)
			got, err := IsMultiPackage(dir)
			if err != nil {
				t.Fatalf("IsMultiPackage: %v", err)
			}
			if got != tt.expect {
				t.Errorf("IsMultiPackage = %v, want %v", got, tt.expect)
			}
		})
	}
}

func TestPackages_Multi(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "alpha"), "alpha.go", `package alpha

func Run() {}
`)
	writeFile(t, filepath.Join(dir, "beta"), "beta.go", `package beta

func Start() error { return nil }
`)

	inv, err := Packages(dir)
	if err != nil {
		t.Fatalf("Packages: %v", err)
	}
	if len(inv.Packages) != 2 {
		t.Fatalf("got %d packages, want 2", len(inv.Packages))
	}

	a := inv.Packages[0]
	if a.Package != "alpha" {
		t.Errorf("Packages[0].Package = %q, want alpha", a.Package)
	}
	if len(a.Files) != 1 {
		t.Errorf("alpha files = %d", len(a.Files))
	}

	b := inv.Packages[1]
	if b.Package != "beta" {
		t.Errorf("Packages[1].Package = %q, want beta", b.Package)
	}
	if len(b.Files[0].Funcs) != 1 || !b.Files[0].Funcs[0].ReturnsError {
		t.Errorf("beta func = %+v", b.Files[0].Funcs)
	}
}

func TestPackage_ExternalTestPackage(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, dir, "lib.go", `package lib

func Hello() string { return "hi" }
`)
	writeFile(t, dir, "lib_test.go", `package lib_test

import "testing"

func TestHello(t *testing.T) {}
`)

	inv, err := Package(dir)
	if err != nil {
		t.Fatalf("Package: %v", err)
	}
	if inv.Package != "lib" {
		t.Errorf("Package = %q, want lib", inv.Package)
	}
	if len(inv.Files) != 2 {
		t.Fatalf("got %d files, want 2", len(inv.Files))
	}
}
