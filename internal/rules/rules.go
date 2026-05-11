package rules

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

func Get(id string) (Rule, bool) {
	r, ok := catalog[id]
	return r, ok
}

func All() []Rule {
	out := make([]Rule, 0, len(catalog))
	for _, id := range order {
		out = append(out, catalog[id])
	}
	return out
}
