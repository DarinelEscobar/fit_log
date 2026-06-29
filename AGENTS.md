# AGENTS.md Instructions for /mnt/c/Users/Cybac/Documents/New_folder/fit_log
## Lean Tooling

Use CodeGraph first for structural questions: routes, controllers, models, services, symbols, callers, callees, impact radius, and related source.

Prefer MCP `codegraph_explore` when available. From PowerShell, use:
- `C:\Users\Cybac\AppData\Roaming\npm\codegraph.cmd status`
- `C:\Users\Cybac\AppData\Roaming\npm\codegraph.cmd explore "order flow"`
- `C:\Users\Cybac\AppData\Roaming\npm\codegraph.cmd query "OrderController"`
- `C:\Users\Cybac\AppData\Roaming\npm\codegraph.cmd sync`

Use Serena for symbol references and precise cross-file refactors. Use `rg` for literal text, config values, logs, comments, and copy.

Do not use another repo-wide search MCP in parallel with CodeGraph. Do not claim CodeGraph or Serena was used unless a tool or command was actually run.

## Working style

Act as a senior software engineer focused on maintainability, clarity, and scalable architecture.

Prefer minimal, well-scoped changes that solve the requested problem without introducing unnecessary complexity.

Before making large or architectural changes, first analyze the existing structure and align with the current patterns unless there is a strong reason to improve them.

When a task is ambiguous or complex, start by outlining a short plan before implementing.

## Code organization

Prefer small and focused files. As a general guideline, keep files around 200-300 lines when reasonable, but prioritize cohesion and readability over strict limits.

Use one clear responsibility per file, component, hook, service, or module.

Use descriptive names in English for files, functions, variables, types, and components.

Separate presentation from logic:
- UI in components
- stateful logic in hooks
- external integrations and side effects in services or adapters

Split code only when it improves clarity, reuse, testability, or maintainability.

Extract subcomponents, hooks, or modules when a file becomes too large, too coupled, or hard to reason about.

## Architecture

Favor clean, modular architecture with clear boundaries between domain, application, and infrastructure when the project size justifies it.

Prefer layered and feature-based organization where appropriate, for example:
- features/
- components/
- hooks/
- services/
- utils/

Avoid circular dependencies.

Keep modules independent, reusable, and easy to test.

Respect the existing project architecture and naming conventions unless the task explicitly requires refactoring.

## React and frontend patterns

Prefer hooks with a single purpose and clear `use*` naming.

Avoid prop drilling beyond 2 levels when composition, context, or a better state boundary would be cleaner.

Keep components focused on rendering and interaction, not business logic.

Prefer controlled abstractions over premature generalization.

## Quality standards

Write code that is easy to read, review, and maintain.

Prefer explicitness over cleverness.

Handle loading, empty, error, and success states when relevant.

Preserve backward compatibility unless a breaking change is requested.

Do not introduce new dependencies unless they provide clear value. Reuse the existing stack whenever possible.

When modifying code, keep diffs as small as possible and avoid unrelated refactors.

## Validation

After making changes, validate them with the appropriate checks when available:
- tests
- lint
- type checks
- build verification

If you cannot run a validation step, state that clearly.

When implementing a fix, explain briefly:
1. what was changed
2. why it was changed
3. any risks or follow-up work

## Performance

Use memoization selectively and only when it solves a real rendering or computation issue.

Prefer simple code first; optimize only when there is a clear reason.

Use route-level or feature-level code splitting when appropriate.

Avoid unnecessary re-renders, duplicated state, and heavy logic inside render paths.

## Output expectations

When generating code:
- follow the project's existing conventions
- do not rename things unnecessarily
- do not rewrite working code without reason
- keep the solution production-oriented
- favor maintainability, scalability, and testability

If multiple valid approaches exist, choose the simplest robust solution and briefly justify it.

