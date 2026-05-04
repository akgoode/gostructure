package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/akgoode/code-structure/internal/dotnetscan"
	"github.com/spf13/cobra"
)

var dotnetCmd = &cobra.Command{
	Use:   "dotnet <assembly.dll>",
	Short: "Scan .NET assembly into structural JSON inventory",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		result, err := dotnetscan.Scan(args[0])
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
	rootCmd.AddCommand(dotnetCmd)
}
