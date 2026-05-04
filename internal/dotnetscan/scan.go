package dotnetscan

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

var ErrNotAssembly = errors.New("path must be a .dll file")

func Scan(assemblyPath string) (*AssemblyInventory, error) {
	absPath, err := filepath.Abs(assemblyPath)
	if err != nil {
		return nil, fmt.Errorf("resolve path: %w", err)
	}

	if !strings.HasSuffix(strings.ToLower(absPath), ".dll") {
		return nil, fmt.Errorf("%s: %w", assemblyPath, ErrNotAssembly)
	}

	if _, err := os.Stat(absPath); err != nil {
		return nil, fmt.Errorf("%s: %w", assemblyPath, err)
	}

	out, err := runScanner(absPath)
	if err != nil {
		return nil, err
	}

	var inv AssemblyInventory
	if err := json.Unmarshal(out, &inv); err != nil {
		return nil, fmt.Errorf("parsing scanner output: %w", err)
	}

	return &inv, nil
}
