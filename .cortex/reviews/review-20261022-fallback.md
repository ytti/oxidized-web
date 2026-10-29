## Code Review: Oxidized Web UI redesign — fresh-context Codex fallback

**Files reviewed:** lib/oxidized/web/views/**, lib/oxidized/web/public/css/oxidized.css, lib/oxidized/web/public/scripts/**
**Iteration:** 1 of 3

Fresh-context Codex fallback review. The required provider review script could not launch because Git Bash failed during startup with `NtCreateDirectoryObject access denied`; no Claude or other external-model review is claimed.

### Findings

#### P2-001: Scrollable configuration panes are not keyboard-focusable
**File:** `lib/oxidized/web/public/css/oxidized.css:695-709`
**Perspective:** Accessibility
**Issue:** The diff and configuration panes set `overflow: auto` (and the diff panes provide horizontal scrolling), but the corresponding `pre`/div elements are not focusable. Their `aria-label` attributes in the diff view do not make generic divs keyboard-scrollable or expose them as named regions.
**Impact:** Keyboard-only users may be unable to scroll through long configurations or across long lines.
**Recommendation:** Make the scroll containers keyboard-focusable (for example, `tabindex="0"`) and expose the diff panes as named regions with an appropriate role; apply the same focus treatment to the configuration `pre` panes.

### Summary
- P0: 0 findings (MUST fix)
- P1: 0 findings (MUST fix)
- P2: 1 finding (file issues)
- P3: 0 findings (file issues)
- **Verdict:** PASS WITH ISSUES

