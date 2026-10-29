## Test Gap Report

**Module:** `lib/oxidized/web` UI redesign
**Tests:** `spec/web/nodes_spec.rb`, `spec/web/node/version_spec.rb`
**Mode:** diff — fresh-context Codex fallback. The provider-aware audit script could not launch because Git Bash returned `NtCreateDirectoryObject` access denied; no external provider ran.

### Behavior Inventory

Behaviors introduced or modified by this diff:

| Behavior | Coverage | Evidence |
|----------|----------|----------|
| Inventory overview counts latest successful, failed, and no-history devices from node data | Covered | `shows only data-backed latest backup counts in the inventory overview` supplies one of each status and asserts each displayed metric is 1. |
| Version history numbering and view/compare action URLs preserve representative version, OID, epoch, and ungrouped node values; comparison is absent for v1 | Shallow | `fetches all versions of a node without a group` asserts v3 and v1 URLs, including `num`, `oid`, `epoch`, and empty `group`, but grouped history action URLs are not asserted. |
| Recent changes shows the five newest modification timestamps, or the empty state when none exist | Missing | No test in the audited specs checks ordering, limit, or empty-state rendering. |
| Inventory and backup-health search fields filter their tables, and clear-search resets the displayed search | Missing | No test exercises the new input handlers, clear buttons, or inventory column-search reset. |
| History marks only the newest version as “Latest”; the raw-download control preserves the current version query and adds text format | Missing | The history spec checks version chips and view/diff URLs, but not the new latest marker or raw-download link. |
| Theme initialization and toggle keep the button’s accessible state in sync and tolerate unavailable local storage | Missing | No browser or script test covers the new persisted-theme handling and ARIA updates. |
| Responsive sidebar opens/closes, hides inactive navigation from assistive technology, and closes on Escape, outside click, or configuration-search selection | Missing | The new `app-shell.js` interaction has no test coverage. |
| Redesigned pages and app shell remain usable at narrow and wide viewport sizes | Missing | The changed layout and responsive CSS have no browser-level verification in the audited specs. |

### Prioritized Gaps

#### P1-001: Verify responsive sidebar interaction and accessibility
**Behavior:** On narrow screens, the sidebar toggle synchronizes open state and accessibility visibility; Escape, outside click, and configuration-search selection close it.
**Status:** Missing
**Why it matters:** A broken close or visibility state can trap navigation or leave hidden links focusable on mobile.
**Suggested test approach:** Browser-test open/close and each dismissal path at mobile width, verify `aria-expanded`, `aria-hidden`/inert behavior, and focus restoration; check desktop resize behavior.

#### P2-001: Verify recent-change ordering and empty state
**Behavior:** The inventory renders up to five devices ordered by descending modification time, or an empty-state message when no timestamps are available.
**Status:** Missing
**Why it matters:** Incorrect ordering or an incorrect empty state would mislead operators about which configurations changed recently.
**Suggested test approach:** Render nodes with more than five distinct modification times and assert the displayed order and limit; render no timestamped nodes and assert the empty-state message.

#### P2-002: Exercise inventory and backup-health search controls
**Behavior:** The new search inputs filter their respective tables, and clear-search restores all rows; inventory clear also clears column filters.
**Status:** Missing
**Why it matters:** The search controls are new interactive behavior and can appear functional while leaving filtered rows hidden or the input value stale.
**Suggested test approach:** Use browser-level interaction to filter each table, clear the search, and confirm all rows return; include an inventory column filter before clearing.

#### P2-003: Check new history markers and raw-download action
**Behavior:** The newest history row receives the “Latest” marker, and the raw-download link preserves the current version query while adding `format=text`.
**Status:** Missing
**Why it matters:** These new labels and the relocated raw action identify the current snapshot and provide its text representation.
**Suggested test approach:** Assert that only the newest row has the marker and that the rendered raw link retains node/OID/epoch/num parameters with text format.

#### P2-004: Verify theme persistence and accessible toggle state
**Behavior:** The saved theme initializes the page, toggling updates the theme and ARIA label/state, and storage errors do not prevent the current-page toggle.
**Status:** Missing
**Why it matters:** The redesign adds persistent theme behavior and exposes the toggle state to assistive technology.
**Suggested test approach:** In a browser, cover saved light/dark initialization, toggle and reload persistence, ARIA state changes, and unavailable local storage.

#### P2-005: Browser-check redesigned page layouts across viewport sizes
**Behavior:** The redesigned inventory, history, stats, configuration, diff, and search pages remain readable and their controls remain reachable across narrow and wide layouts.
**Status:** Missing
**Why it matters:** The diff substantially changes shared layout and styles, while the audited request specs cannot detect clipping, overlap, or unreachable controls.
**Suggested test approach:** Capture representative inventory, history, and configuration pages at mobile and desktop widths and inspect overflow, table controls, navigation, and action reachability.

#### P2-006: Assert grouped history action parameters after the markup change
**Behavior:** Version download and compare links retain the node’s group value when history is rendered for a grouped node.
**Status:** Shallow
**Why it matters:** The existing grouped-history example checks that the page renders and shows v3, but not that action URLs still route to the correct grouped configuration.
**Suggested test approach:** In the grouped history spec, assert representative view and diff hrefs include the expected group, OID, epoch, and version number.

### Summary
- Covered: 1
- Shallow: 1
- Missing: 6
- P0: 0
- P1: 1
- P2: 6

