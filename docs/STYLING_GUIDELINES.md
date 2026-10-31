# Skycom Styling Guidelines

This document is the contract for colors, grouping, and Tailwind usage in Skycom.

---

## 1. Semantic colors only

All colors come from the semantic tokens defined in
`app/assets/tailwind/application.css`. Components use the semantic utilities and
**never** raw Tailwind palette classes.

```javascript
// ✅ CORRECT
<button class="px-4 py-2 bg-primary text-primary-foreground rounded-lg">Save</button>

// ❌ WRONG — raw palette class; bypasses the theme and breaks a rebrand
<button class="px-4 py-2 bg-blue-600 text-white rounded-lg">Save</button>
```

Raw palette classes are any of:
`bg-*`, `text-*`, `border-*`, `ring-*`, `divide-*`, `from-*`, `via-*`, `to-*`,
`outline-*`, `shadow-*`, `fill-*`, `stroke-*`, `placeholder:*`, `accent-*`,
`caret-*`, `decoration-*` followed by a Tailwind palette name and optional shade
(`slate`, `gray`, `red`, `emerald`, `blue`, `white`, `black`, …).

Enforced by `bin/check_colors` (see §10).

---

## 2. The tokens

Defined once in `:root` (light) and `.dark`. Use the utility, not the variable.

| Utility | Purpose | Light source | Dark source |
|---|---|---|---|
| `bg-background` / `text-background` | Page background | slate-50 | slate-950 |
| `bg-card` | Panels, cards, sidebars, inputs, dropdowns | white | slate-900 |
| `bg-muted` | Subtle fills: hover states, table headers, chips | slate-100 | slate-800 |
| `border-line` / `divide-line` | Every border and divider | slate-200 | slate-700 |
| `bg-overlay` | Modal scrim / image scrim | black 45% | black 60% |
| `text-foreground` | Primary text | slate-900 | slate-100 |
| `text-muted-foreground` | Secondary text, labels, placeholders, icons | slate-500 | slate-400 |
| `text-overlay-foreground` | Text on top of `bg-overlay` | white | white |
| `bg-foreground` / `text-background` | Inverse surface: tooltips, neutral toast, dark FAB | slate-900 / slate-50 | slate-100 / slate-950 |
| `bg-primary` / `text-primary` / `border-primary` / `ring-primary` | Brand: buttons, links, focus rings, active state | indigo-600 | indigo-400 |
| `text-primary-foreground` | Text on solid brand | white | slate-950 |
| `success` | Positive: completed, active, paid | emerald-600 | emerald-400 |
| `warning` | Attention: pending, low stock, due soon | amber-600 | amber-400 |
| `danger` | Destructive: delete, failed, overdue | red-600 | red-400 |
| `info` | Neutral information: notes, tips | blue-600 | blue-400 |
| `*-foreground` | Text/icon on the matching solid status | white / slate-900 | slate-950 |

**Rebranding the app** = change `--primary` and `--primary-foreground` in
`app/assets/tailwind/application.css`. Nothing else needs to change.

**Adding a token** = three lines (`:root`, `.dark`, `@theme inline`). Do not add a
token that duplicates an existing one.

---

## 3. No `dark:` for themed colors

The variable already switches. Adding `dark:` is a bug — it overrides the token
and reintroduces per-component theming.

```javascript
// ✅ CORRECT — one class, both modes
<div class="bg-card border border-line text-foreground">
  <p class="text-muted-foreground">Secondary</p>
</div>

// ❌ WRONG — the variable already handles dark mode
<div class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white">
  <p class="text-slate-500 dark:text-slate-400">Secondary</p>
</div>
```

`dark:` is still valid for **non-color** concerns (e.g. `hidden dark:flex`) and
for the icons in `darkmode_controller.js`.

### 3.1 How dark mode works (read before debugging "dark doesn't stick")

Tailwind v4 class strategy — `app/assets/tailwind/application.css`:

```css
@custom-variant dark (&:where(.dark, .dark *));
```

Every `dark:` class activates only when an ancestor (here `<html>`) carries
class `dark`. There is no `tailwind.config.*` and no media-query fallback.

| Piece | File | Role |
|-------|------|------|
| Source of truth | `localStorage["darkmode"]` (`"true"` / `"false"`) | Persisted preference |
| Pre-paint apply | Inline `<script>` in `app/views/layouts/application.html.erb` + `admin.html.erb` + `mobile.html.erb` `<head>` | Adds `dark` to `<html>` before first paint (no FOUC, no Stimulus dependency) |
| Toggle + re-apply | `app/javascript/controllers/darkmode_controller.js` | Header button (`Helpers.darkmodeTrigger()` in `layout_controller.js`) toggles via the `darkmode` value; `initialize()`/`connect()` re-apply stored theme on every boot/Turbo navigation; `triggerTargetConnected()` re-injects icons whenever the layout re-renders the header |
| Icons | Same controller (`triggerHTML()`) | Moon (`flex dark:hidden`) / sun (`hidden dark:flex`) — pure CSS swap, no JS state |

Rules:

- **Never gate theme application on the header trigger existing.** The layout renders the trigger asynchronously (after the client cache resolves); the old code waited for it and dropped the theme on slow pages.
- **Toggle through the `darkmode` value** (`toggleDarkmode()` sets the value; `darkmodeValueChanged()` writes DOM + storage). Bypassing the value leaves DOM/value/storage diverged.
- **Keep the head pre-apply script in sync** with the storage key if either ever changes.
- Regression coverage: `spec/features/companies/layouts/darkmode_spec.rb` (toggle, reload persistence, Turbo sidebar navigation, all sidebar index pages).

### 3.2 Why `@theme inline`

`@theme inline` tells Tailwind to keep a live `var()` reference in each utility
instead of baking the value at build time. That is what makes one variable
change repaint every `bg-primary`, `text-primary`, `border-primary`, etc.

```css
:root        { --primary: oklch(0.511 0.262 276.966); }
.dark        { --primary: oklch(0.673 0.182 276.935); }
@theme inline { --color-primary: var(--primary); }
```

---

## 4. Opacity modifiers instead of extra shades

The old palette needed three tokens per color (`bg-blue-50`, `bg-blue-600`,
`dark:bg-blue-900/30`). The semantic system needs one, plus `/N`.

```javascript
// Soft background + matching text + subtle border
<span class="bg-success/10 text-success border border-success/20 rounded-full px-2 py-0.5 text-xs">
  Active
</span>

// Hover
<button class="bg-primary text-primary-foreground hover:bg-primary/90">Save</button>
```

Opacity modifiers work on every token (`bg-primary/10`, `border-danger/30`,
`text-muted-foreground/70`, `bg-overlay/60`).

---

## 5. Grouping & Borders (mandatory)

Every logical UI group (title+value pair, card, dropdown, table, section, panel)
must be visually separated in **both** light and dark mode using one of:

- a distinct background (`bg-card`, `bg-muted`, `bg-background`), or
- a border (`border border-line`, `divide-y divide-line`).

Never leave a group with no visual separation. The tokens handle dark mode, so
one class covers both.

```javascript
// ✅ CORRECT — bordered stat card, no dark: variants needed
<div class="p-3 border border-line rounded-lg bg-card">
  <p class="text-xs font-medium text-muted-foreground">Month</p>
  <p class="text-sm font-semibold text-foreground">October 2026</p>
</div>

// ❌ WRONG — no border and no distinct background
<div>
  <p class="text-xs font-medium text-muted-foreground">Month</p>
  <p class="text-sm font-semibold text-foreground">October 2026</p>
</div>
```

Reference implementations: `companies/employees/show_controller.js`,
`companies/attendance_months/show_controller.js`.

---

## 6. Data palettes are not theme colors

Some colors are **user data**, not styling:

- workflow-step colors (`text_color` / `background_color` on `WorkflowStep`)
- chart series

They still resolve to semantic tokens — never raw palette names:

- **Workflow steps** are picked from `helpers/workflow_colors.js`, mirrored in
  `config/initializers/constants.rb` (`WORKFLOW_STEP_COLORS`). The DB stores the
  semantic class pair (e.g. `text-primary` + `bg-primary/10`), so a rebrand
  recolors every step automatically. Keep both files in sync.
- **Chart series** come from `helpers/chart_colors.js`, which reads the live CSS
  variables (`--primary`, `--success`, …) at render time. Never hardcode a hex
  palette in a chart.

Only third-party stylesheets (`toastify.css`, `hint.css`) and literal brand art
(Google logo fills, icon SVGs) may keep hardcoded colors.

---

## 7. cursor-pointer for Clickable Elements

Always add `cursor-pointer` to any clickable element (buttons, links, icons,
checkboxes).

```javascript
// ✅ CORRECT
<button class="px-4 py-2 bg-primary text-primary-foreground rounded-lg cursor-pointer">Click</button>
<button class="p-2 text-muted-foreground hover:text-primary rounded-lg cursor-pointer">
  <span class="material-symbols-outlined">edit</span>
</button>

// ❌ WRONG — missing cursor-pointer
<button class="px-4 py-2 bg-primary text-primary-foreground rounded-lg">Click</button>
```

---

## 8. Mobile First

Write base styles for mobile, then use `md:` or `lg:` breakpoints for larger
screens.

```javascript
// ✅ CORRECT
<button class="px-4 py-2 md:px-6 md:py-3 bg-primary text-primary-foreground rounded-lg">
  Save
</button>

// ❌ WRONG — desktop first
<button class="md:px-6 md:py-3 bg-primary text-primary-foreground rounded-lg">
  Save
</button>
```

---

## 9. Class formatting

**Single line classes.** Never split Tailwind classes across multiple lines,
even if long.

```javascript
// ✅ CORRECT
<button class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer md:px-6 md:py-3">
  Save
</button>

// ❌ WRONG
<button class="
  flex items-center justify-center gap-2
  px-4 py-2 bg-primary
  text-primary-foreground rounded-lg
">
  Save
</button>
```

**Multi-line attributes.** When an element has many attributes, put each
attribute on its own line.

```javascript
// ✅ CORRECT
<button
  type="button"
  data-action="click->${this.identifier}#deleteEmployee"
  class="px-4 py-2 text-sm font-medium bg-danger/10 text-danger hover:bg-danger/20 rounded-lg transition-colors cursor-pointer"
>
  Delete
</button>
```

---

## 10. Enforcement

```bash
bin/check_colors            # report
bin/check_colors --strict   # fail on violations (CI)
bin/check_colors --all      # every distinct raw token
bin/check_colors --files    # per-file counts
```

The guard flags:

1. raw palette classes in `app/javascript/**/*.js` and `app/views/**/*.erb`
2. `dark:` applied to a semantic token
3. arbitrary color values (`bg-[#fff]`, `text-[rgb(...)]`)

Allowlist: currently empty. Third-party stylesheets are not scanned, and brand
art (icon/logo SVG fills) is not class-based.

---

## 11. Typography

Two Google Fonts families are loaded in every HTML layout (`application`,
`admin`, `mobile`):

| Role | Family | Utility |
|---|---|---|
| Body, labels, controls | Inter | default / `font-sans` |
| Headings, display text | Plus Jakarta Sans | `font-display` |

- `--font-sans` in `app/assets/tailwind/application.css` is Inter, so all
  unstyled text and every `font-sans` utility use it.
- `h1`–`h6` use `--font-display` via a base-layer rule. Use `font-display`
  explicitly for non-heading display text.
- Do not reintroduce Lexend or per-component font stacks.

---

## Quick Reference

| Guideline | Rule |
|-----------|------|
| Colors | Semantic tokens only — never `bg-white`, `text-slate-500`, `border-slate-200` |
| Brand | `bg-primary` / `text-primary` / `ring-primary` |
| Text | `text-foreground` (primary), `text-muted-foreground` (secondary) |
| Borders | `border border-line`, `divide-y divide-line` |
| Dark mode | Never `dark:` a color — the variable switches |
| Transparency | Opacity modifier: `bg-primary/10`, `border-danger/30` |
| Clickable | Always `cursor-pointer` |
| Responsive | Mobile first, then `md:` / `lg:` |
| Classes | Single line only |
| Attributes | Multi-line when many |
| Fonts | Inter body; Plus Jakarta Sans headings (`font-display`) |
| Check | `bin/check_colors --strict` |

---

*End of documentation*
