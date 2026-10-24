# UI redesign implementation plan

## Product scope

Modernize the existing Oxidized Web interface as a server-rendered enterprise operations dashboard, keeping Sinatra, Haml, the Oxidized nodes API, current REST endpoints, and vendored browser libraries.

## Incremental change loops

Each substantial slice follows the Claude-Cortex agent-loops Code Change Loop, Test Writing Loop, and Lint Gate. Initially the user prohibited commits. Later approval authorizes runtime installation and commit/PR after successful checks. Provider scripts initially failed in the sandbox; a later Claude retry outside it failed due to insufficient credit. Fresh-context Codex review and test-audit fallbacks were used. The local Cortex CLI is usable through its Python module entry point. No successful Claude review is claimed, and no GitHub issues were filed.

1. **Shared shell and design tokens** — establish semantic light/dark CSS variables, responsive sidebar/header/content structure, accessible active navigation, page titles, and theme persistence. Retain all existing assets.
2. **Overview and device inventory** — derive only data-backed summary cards from existing node status/statistics; improve device grouping, model visibility, last status/time, search, and actions while preserving DataTables state, visibility controls, routes, and reload feedback.
3. **History and configuration views** — improve version context, timestamps, download affordances, historical config display, and keep raw download behavior intact.
4. **Comparison view** — retain `diff_view` and server-side comparison selection, render responsive side-by-side code panes with explicit version labels, line wrapping/scroll behavior, and added/removed/context highlighting.
5. **Evidence and documentation** — add/refresh the six requested redesign reports with exact changed files, tested commands and outputs, reviewer provider/result, known limitations, and remaining items.

## Constraints and risks

- No route, backend, endpoint, data-shape, dependency, credential, production, or deployment changes.
- Do not infer Cisco or MikroTik inventory from unavailable fields; display the existing model value as supplied.
- Keep all user-controlled content escaped, including node names, group labels, and diff/config content.
- Preserve URI prefix support by using `url_for` on internal navigation.
- Keep keyboard focus visible, semantic landmarks, accessible names for icon actions, contrast-aware status labels, responsive overflow, and reduced-motion handling.
- Theme is browser-local; it does not alter server configuration.
- Browser automation is not currently configured in the repository. Report it unavailable if no existing browser path can be used.

## Verification and review gates

- Run current Minitest suite via the repository-supported Rake task when Ruby/Bundler are available.
- Run Ruby syntax/Haml render and RuboCop if the respective runtime/gems exist.
- Run JavaScript syntax checks using the installed Node runtime if available.
- Use existing tests for route and data compatibility. Add only focused coverage relevant to changed behavior.
- Run the installed Cortex `specialist-review.sh` for source and `diff-test-audit.sh` for changed tests, Claude-first; use the documented fresh-context Codex reviewer only if scripted providers fail and the fallback is actually available.
- Review findings for Ruby/Haml, routing/data behavior, UI, JavaScript, escaping, accessibility, responsiveness, and maintainability. Resolve P0/P1 before completion; list remaining P2/P3.
- Later user approval authorizes runtime/dependency installation, and commit/push/PR after successful checks. Merge, deployment, and backend modifications remain prohibited.

## Completion update

The planned UI slices are complete. Ruby, Haml, Node, RuboCop, and synthetic Chrome checks have executed successfully; exact results and provider limitations are in TEST-RESULTS.md and REVIEW-RESULTS.md.

