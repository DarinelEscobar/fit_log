# Repository ExecPlan Standard

Use an ExecPlan for complex features, migrations, releases, integrations, or other work that spans multiple dependent milestones. Store plans in `.agent/execplans/` using descriptive kebab-case names.

An ExecPlan is a living, self-contained implementation guide and durable record. A new engineer or agent must be able to understand the repository context, execute the work, and prove the intended outcome without relying on prior conversation.

## Planning rules

- Ground plans in the current repository, its instructions, and its existing architecture.
- Keep implementation, tests, local validation, documentation, acceptance criteria, and completion gate together in each vertical milestone.
- Use `depends_on` as the only dependency source. Do not add a `blocks` field.
- Follow the user's execution strategy. Sequential work is valid; `parallelizable: true` records eligibility but does not authorize spawning workers.
- Preserve unrelated working-tree changes.
- Keep substantive content in Markdown and reserve YAML for milestone metadata.

## Milestone states

Use only `pending`, `in_progress`, `blocked`, and `completed`.

A milestone is completed only when all listed validation commands pass and every observable acceptance criterion is satisfied.

## Living sections

Keep `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` synchronized with reality. Record evidence, not guesses. Add a revision entry when the plan materially changes.

## Execution boundary

Planning alone does not authorize implementation. An explicit request to implement, a plan approval, or `$execute-plan` does. Implementation authorization is separate from commit, merge, push, deployment, and release authorization; record and honor each action independently.
