package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/akgoode/code-structure/internal/rules"
	"github.com/spf13/cobra"
)

var jsonOutput bool

var rulesCmd = &cobra.Command{
	Use:   "rules [rule-id]",
	Short: "List rules or look up a specific rule by ID",
	Long: `Without arguments, lists all rules with ID, severity, and title.
With a rule ID argument, shows the full rule detail including rationale,
exceptions, and judgment guidance for warnings.`,
	Args: cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 1 {
			return showRule(args[0])
		}
		return listRules()
	},
}

func init() {
	rulesCmd.Flags().BoolVar(&jsonOutput, "json", false, "output as JSON")
	rootCmd.AddCommand(rulesCmd)
}

func listRules() error {
	all := rules.All()

	if jsonOutput {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		return enc.Encode(all)
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tSEVERITY\tCATEGORY\tTITLE")
	for _, r := range all {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", r.ID, r.Severity, r.Category, r.Title)
	}
	return w.Flush()
}

func showRule(id string) error {
	r, ok := rules.Get(strings.ToUpper(id))
	if !ok {
		return fmt.Errorf("unknown rule: %s", id)
	}

	if jsonOutput {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		return enc.Encode(r)
	}

	fmt.Printf("%s  [%s]  %s\n", r.ID, r.Severity, r.Title)
	fmt.Printf("Category: %s\n\n", r.Category)
	fmt.Println(r.Description)

	if r.Rationale != "" {
		fmt.Printf("\nRationale:\n  %s\n", r.Rationale)
	}
	if r.Exceptions != "" {
		fmt.Printf("\nExceptions:\n  %s\n", r.Exceptions)
	}
	if r.Judgment != "" {
		fmt.Printf("\nJudgment:\n  %s\n", r.Judgment)
	}

	return nil
}
