package worker

import rego.v1

has_exported_func(name) if {
	some file in input.files
	not file.is_test
	some f in file.funcs
	f.exported
	f.name == name
}

# METADATA
# title: Missing worker constructor
# description: >
#   Every worker package must export New(cfg Config) (*Worker, error) or
#   NewWorker(...). The constructor wires dependencies and validates reachability.
violation_missing_constructor contains obj if {
	not has_exported_func("New")
	not has_exported_func("NewWorker")
	obj := {
		"msg": concat("\n", [
			"MISSING: New(cfg Config) (*Worker, error)",
			"",
			"Every worker package must export a constructor that wires dependencies and",
			"returns the worker. The constructor receives a Config struct (or individual",
			"dependencies) and returns the assembled worker ready to run.",
			"",
			"The worker struct holds everything RunOnce needs — database connections,",
			"API clients, configuration. The constructor validates that dependencies",
			"are reachable and returns an error if the worker can't start.",
			"",
			"Example:",
			"  type Worker struct {",
			"      board  boardClient",
			"      runDB  runStore",
			"      logger *slog.Logger",
			"      cfg    Config",
			"  }",
			"",
			"  func New(cfg Config) (*Worker, error) {",
			"      db, err := sql.Open(\"postgres\", cfg.DatabaseURL)",
			"      if err != nil {",
			"          return nil, fmt.Errorf(\"connect to database: %w\", err)",
			"      }",
			"      return &Worker{",
			"          board:  trello.New(cfg.APIKey, cfg.Token),",
			"          runDB:  &pgRunStore{db: db},",
			"          logger: cfg.Logger,",
			"          cfg:    cfg,",
			"      }, nil",
			"  }",
		]),
		"rule_id": "GO-WORK-001",
		"severity": "error",
	}
}

# METADATA
# title: Missing RunOnce function
# description: >
#   Every worker must export RunOnce(ctx context.Context) error. It performs a
#   single idempotent execution cycle, safe to call repeatedly on a schedule.
violation_missing_runonce contains obj if {
	not has_exported_func("RunOnce")
	obj := {
		"msg": concat("\n", [
			"MISSING: RunOnce(ctx context.Context) error",
			"",
			"Every worker must export a RunOnce function that performs a single execution",
			"cycle. The caller (main.go or a scheduler) calls RunOnce in a loop or on a",
			"cron schedule. RunOnce does one unit of work and returns.",
			"",
			"This is the workflow — the orchestration that reads like English. Each line",
			"should be a named step: find work, pick the highest priority item, process",
			"it, record the outcome. Implementation details live behind those names.",
			"",
			"RunOnce must be safe to call repeatedly. If there's no work, it returns nil.",
			"If it fails partway through, the next call should be able to pick up cleanly.",
			"The context carries cancellation signals from the caller.",
			"",
			"Example:",
			"  func (w *Worker) RunOnce(ctx context.Context) error {",
			"      cards, err := w.board.ActionableCards(w.cfg.BoardID)",
			"      if err != nil {",
			"          return fmt.Errorf(\"fetch actionable cards: %w\", err)",
			"      }",
			"      if len(cards) == 0 {",
			"          return nil",
			"      }",
			"      picked := pickHighestPriority(cards)",
			"      result := w.execute(ctx, picked)",
			"      w.recordOutcome(picked, result)",
			"      return nil",
			"  }",
		]),
		"rule_id": "GO-WORK-002",
		"severity": "error",
	}
}
