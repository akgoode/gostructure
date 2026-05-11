package rules

import (
	_ "embed"
	"encoding/json"
	"strings"
)

//go:embed rules.json
var rulesJSON []byte

type Rule struct {
	ID          string `json:"id"`
	Severity    string `json:"severity"`
	Category    string `json:"category"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Rationale   string `json:"rationale,omitempty"`
	Exceptions  string `json:"exceptions,omitempty"`
	Judgment    string `json:"judgment,omitempty"`
}

func (r Rule) IsWarning() bool {
	return r.Severity == "warning"
}

var (
	catalog []Rule
	index   map[string]Rule
)

func init() {
	if err := json.Unmarshal(rulesJSON, &catalog); err != nil {
		panic("rules: invalid rules.json: " + err.Error())
	}
	index = make(map[string]Rule, len(catalog))
	for _, r := range catalog {
		index[r.ID] = r
	}
}

func Get(id string) (Rule, bool) {
	r, ok := index[strings.ToUpper(id)]
	return r, ok
}

func All() []Rule {
	return catalog
}
