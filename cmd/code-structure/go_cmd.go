package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/akgoode/code-structure/internal/goscan"
	"github.com/spf13/cobra"
)

var goCmd = &cobra.Command{
	Use:   "go <directory>",
	Short: "Scan Go packages into structural JSON inventory",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		result, err := goscan.Scan(args[0])
		if err != nil {
			return err
		}

		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		if err := enc.Encode(result); err != nil {
			return fmt.Errorf("encoding output: %w", err)
		}
		return nil
	},
}

func init() {
	rootCmd.AddCommand(goCmd)
}
