## Test Gap Report

**Module:** `lib/oxidized/web/views`, `lib/oxidized/web/public/scripts`
**Tests:** `spec/web/nodes_spec.rb`, `spec/web/node/version_spec.rb`, `spec/js/app-shell.test.js`, `spec/js/theme-toggle.test.js`, `.cortex/verification/browser-check.cjs`
**Mode:** diff
**Runtime verification (executed):** Ruby suite: 59 runs, 253 assertions, 0 failures/errors/skips; RuboCop: 16 files, 0 offenses; 10 Haml templates compile and Ruby source/spec syntax passes. Playwright Chrome ran against the local synthetic fixture: inventory and stats search/reset each changed 3 rows to 1 and back to 3, and their Columns choosers hid then restored inventory Group (index 3) and stats Total Failures (index 2); desktop 1440 and mobile 390 navigation, Escape focus return, inert/hidden state, hidden-sidebar bounds, no page-wide horizontal overflow, theme persistence, version/config/diff routes and old/new content passed; no browser JS errors. Screenshots are in `docs/redesign/screenshots/`.
**Provider review:** Cortex Claude workflow returned `Credit balance is too low`; no provider review result is claimed. The fresh-context fallback artifact reports a static review with no findings. This report is an independent diff test audit.

### Behavior Inventory

Behaviors introduced or modified by this diff:

| Behavior | Coverage | Evidence |
|----------|----------|----------|
| Inventory summary shows total, successful, failed, and no-history counts | Covered | `shows only data-backed latest backup counts in the inventory overview` asserts total=4 with one success, one failure, one no-history device, and an unknown status excluded from those categories; the empty-inventory spec asserts total=0. |
| Recent changes are limited to the five newest modification timestamps and ordered newest first | Covered | `lists the five devices with the newest modification timestamps` verifies order and exclusion of the sixth. |
| Recent changes show an empty state when there is no usable timestamp | Covered | `shows an empty recent-changes state when listed devices have no modification timestamps` uses two listed nodes with nil `mtime` and asserts the empty state and absence of recent rows. |
| Version history labels, latest marker, and per-version download/compare links reflect the version number and node group | Covered | Version specs assert v3/latest, view and diff URLs, grouped URLs, and that version 1 has no compare link. |
| Version snapshot page exposes a raw text download link | Covered | `fetches a previous version from git` checks the `format=text` link. |
| Diff page preselects the requested comparison version and renders old/new lines in their labeled panes | Covered | The diff spec asserts selected C001, both pane labels, and that old and new changed lines appear only in their respective panes; browser fixture also confirms old/new diff contents. |
| Theme initializes from storage, persists toggles, falls back when storage throws, and updates accessible button state | Covered | Theme tests assert saved-dark initialization, storage persistence, storage failure fallback, `aria-pressed`, and labels; Playwright confirms persistence across reload and light/dark switching. |
| Mobile sidebar opens/closes with focus, ARIA, search focus, Escape, outside-click, and resize state handling | Covered | Five `app-shell.test.js` tests assert transitions and focus effects; Playwright confirms Escape returns focus and the closed sidebar is inert and outside the viewport at 390px. |
| Sidebar and page layouts adapt between desktop and mobile widths | Covered | Playwright exercised 1440px and 390px layouts, checked mobile sidebar visibility after Escape and no document-wide horizontal overflow. |
| Inventory and backup-history search and reset filter and restore visible table rows | Covered | Playwright verified both tables transition from 3 visible rows to 1 matching row and back to 3 after reset. |
| DataTables column visibility control changes table columns | Covered | The Playwright harness activated each chooser, hid and restored inventory Group at index 3 and stats Total Failures at index 2, and asserted DataTables visibility false then true. |

### Prioritized Gaps

_No prioritized gaps._

### Summary
- Covered: 11
- Shallow: 0
- Missing: 0
- P0: 0
- P1: 0
- P2: 0




