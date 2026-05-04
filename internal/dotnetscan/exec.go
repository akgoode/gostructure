package dotnetscan

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

const scannerBinary = "dotnet-scanner"

func findScanner() (string, error) {
	if env := os.Getenv("CODESTRUCTURE_DOTNET_SCANNER"); env != "" {
		if _, err := os.Stat(env); err == nil {
			return env, nil
		}
		return "", fmt.Errorf("CODESTRUCTURE_DOTNET_SCANNER set to %s but file not found", env)
	}

	self, err := os.Executable()
	if err == nil {
		sibling := filepath.Join(filepath.Dir(self), scannerBinary)
		if _, err := os.Stat(sibling); err == nil {
			return sibling, nil
		}
	}

	if path, err := exec.LookPath(scannerBinary); err == nil {
		return path, nil
	}

	return "", fmt.Errorf("%s not found: build it with 'dotnet publish tools/dotnet-scanner' or set CODESTRUCTURE_DOTNET_SCANNER", scannerBinary)
}

func runScanner(assemblyPath string) ([]byte, error) {
	scanner, err := findScanner()
	if err != nil {
		return nil, err
	}

	cmd := exec.Command(scanner, assemblyPath)
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("dotnet-scanner failed: %w", err)
	}
	return out, nil
}
