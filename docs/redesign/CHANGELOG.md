# Redesign changelog

## 2026-10-22 — Enterprise UI redesign

### Added

- Responsive application shell with sidebar navigation, device inventory, backup health, and configuration search entry points.
- Data-backed latest-backup summary cards and a recent-modification list on the inventory page.
- Design tokens with light/dark themes, responsive tables, configuration panels, history rows, and two-pane diffs.
- Accessible labels for icon actions, live reload feedback, mobile navigation controls, and keyboard-focusable configuration/diff regions.
- Redesign architecture, design-system, implementation-plan, test-results, and review-results documentation.

### Changed

- Redesigned inventory, device details, backup statistics, configuration search results, configuration history, historical configuration, and comparison pages while retaining existing route contracts and bundled dependencies.
- Kept the existing local theme preference and made it resilient when browser storage is unavailable.

### Fixed

- Made long configuration and diff panes keyboard-scrollable and exposed them as named regions.

### Limitations

- Cisco/MikroTik recognition remains dependent on the model string Oxidized supplies.
- A configuration change is represented by the existing node modification timestamp; no change-event feed or additional backend statistics were added.
- Verification ran against synthetic data in installed Chrome. Live backup execution and other browser engines were not exercised; see `TEST-RESULTS.md`.

### Changed files

- Shared layout: lib/oxidized/web/views/layout.haml, head.haml, footer.haml.
- Pages: lib/oxidized/web/views/nodes.haml, stats.haml, node.haml, conf_search.haml, versions.haml, version.haml, diffs.haml.
- Browser assets: lib/oxidized/web/public/css/oxidized.css and scripts/theme-toggle.js; added scripts/app-shell.js.
- Tests: spec/web/nodes_spec.rb, spec/web/node/version_spec.rb, new spec/js/app-shell.test.js and theme-toggle.test.js; package.json adds the Node test command.
- Documentation: all six reports under docs/redesign plus five synthetic-data screenshots.
- Cortex evidence: independent reviews/audits and optional local browser fixture/check under .cortex.
