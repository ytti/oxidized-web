# Oxidized Web design system

## Design direction

The interface uses a restrained network-operations visual language: a persistent navy navigation rail, neutral work surface, high-contrast typography, compact data tables, and color reserved for backup outcomes and diff changes. Existing Bootstrap 5 and Bootstrap Icons are retained. No runtime or asset dependency was added.

## Tokens

Tokens live in `lib/oxidized/web/public/css/oxidized.css` under the `--ow-*` namespace.

| Category | Tokens and intent |
|---|---|
| Surface | `--ow-color-canvas`, `--ow-color-surface`, `--ow-color-surface-muted`, and `--ow-color-sidebar` define work, card, inset, and navigation surfaces. |
| Text | `--ow-color-text`, `--ow-color-text-muted`, `--ow-color-sidebar-text`, and `--ow-color-sidebar-muted` distinguish primary and supporting information. |
| Status | `--ow-color-success`, `--ow-color-danger`, `--ow-color-warning` and their `*-soft` surfaces encode outcomes and diff annotations. Labels remain visible so status does not rely on color alone. |
| Accent | `--ow-color-accent` and `--ow-color-accent-soft` identify interactive controls and focused navigation. |
| Typography | `--ow-font-sans` for interface text and `--ow-font-mono` for configuration content. |
| Spacing | `--ow-space-1` through `--ow-space-6` provide a quarter-rem-based scale. |
| Shape and depth | `--ow-radius-sm`, `--ow-radius-md`, `--ow-radius-lg`, and `--ow-shadow-sm` keep controls and panels consistent. |
| Layout | `--ow-sidebar-width`, `--ow-topbar-height`, and `--ow-content-width` define the desktop shell. |
| Motion | `--ow-transition-fast` is used for small navigation feedback; reduced-motion preferences shorten transitions. |

The `[data-bs-theme="dark"]` selector overrides semantic color tokens while preserving shared component structure. Theme choice persists in browser `localStorage`; if storage is unavailable, the toggle still changes the active page.

## Components

- **Application shell:** fixed desktop sidebar, sticky top bar, focused configuration search, page content container, and product/version footer.
- **Responsive navigation:** collapses into an off-canvas drawer below 992px. The menu button announces expanded state, opens focus on the first nav item, closes on Escape or outside click, and returns focus on Escape.
- **Metric cards:** total listed devices, devices whose latest run succeeded, devices whose latest run failed, and devices with no latest run. Counts use only the current `/nodes` response.
- **Tables:** inventory and backup-health tables keep DataTables paging, sorting, state saving, column visibility, model/group links, and horizontal overflow. Inventory uses a labeled external search input connected to DataTables.
- **Status badges:** always show the state label with semantic text and background colors.
- **Configuration panels:** scrollable monospace blocks; historical configuration and device metadata are named, keyboard-focusable regions.
- **Diff panels:** labeled, keyboard-focusable side-by-side previous/current panes at wide widths; stacked panes on phones; each pane scrolls independently in both axes.
- **Action links:** icon affordances use action-specific accessible names and visible hover/focus feedback.

## Responsive behavior

| Viewport | Shell | Content |
|---|---|---|
| ≥ 992px | 248px fixed sidebar and sticky top bar. | Four summary cards, table overflow on narrow data, two diff columns. |
| 576–991px | Sidebar becomes an off-canvas drawer with backdrop and keyboard dismissal. | Two summary-card columns; content padding reduces. |
| ≤ 575px | Compact top bar with menu, search, and theme controls. | Summary cards remain two columns; page actions wrap; configuration tables scroll horizontally; diff panes stack. |

## Accessibility notes

- Navigation is a labeled landmark, current page links use `aria-current`, controls have visible focus rings, and icon-only actions have explicit names.
- Search controls use labels (visually hidden when placeholder text is present); reload feedback is announced through a live status region.
- Status meaning is stated in text. The design honors `prefers-reduced-motion`.
- Long configuration and diff panels accept keyboard focus and expose region names for assistive technology.
- No automated contrast checker or browser-driven responsive/theme test is currently configured; those checks are listed with actual availability in `TEST-RESULTS.md`.
