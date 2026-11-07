# Skycom Agent Playbook — How We Build

> Read this before planning or implementing a multi-step UI feature, settings page, or refactor.
>
> It captures the working method, UI/UX philosophy, frontend mechanics, backend discipline, and definition of done behind Skycom's strongest configuration-page refactors.
>
> Pair this with `docs/PLAN_TEMPLATE.md`. The plan is part of the deliverable, not a chat artifact.

## Contents

1. [When to use this playbook](#1-when-to-use-this-playbook)
2. [North star](#2-north-star)
3. [How to understand a request](#3-how-to-understand-a-request)
4. [How to plan](#4-how-to-plan)
5. [UI/UX principles](#5-uiux-principles)
6. [Frontend mechanics](#6-frontend-mechanics)
7. [Backend and data principles](#7-backend-and-data-principles)
8. [Testing and verification](#8-testing-and-verification)
9. [Definition of done](#9-definition-of-done)
10. [Anti-patterns](#10-anti-patterns)
11. [Canonical plan shape](#11-canonical-plan-shape)

---

## 1. When to use this playbook

Use it when:

- a page needs a UX rethink, not a one-line fix
- a settings/configuration surface is growing complex
- the change spans frontend + backend + model validation + tests + docs
- you need a plan another session can execute without the current conversation

For a one-line fix, just fix it. For a multi-step change, follow this.

---

## 2. North star

**Make powerful configuration feel obvious.**

- Design for the non-technical manager, not the database administrator.
- Hide the machinery. Show the meaning.
- Keep the surface simple; keep the implementation rigorous.
- Every control should answer:
  - What does this do?
  - What will change?
  - What happens to existing data?
  - What is the next obvious action?

The best configuration page feels like a short conversation:

> “Here is what you can change. Here is what it does. Here is what happens when you save.”

Not like a database console.

---

## 3. How to understand a request

Before proposing anything:

1. **Read the real thing.** Open the page, controller, model, specs, and docs. Do not design from the request text alone.
2. **Identify the actor and their vocabulary.** Is the user a manager, an operator, a cashier, a developer? Use their words, not schema words.
3. **Separate the domain concept from its storage.**
   - “Membership tier” is the concept.
   - A typed storage slot plus an option list is the storage.
   - The user should only ever see the concept.
4. **Find the single owner of each concept.**
   - Who owns the label?
   - Who owns the type?
   - Who owns visibility, order, or layout?
   - Who owns validation?
   - If two pages own the same value, stop and choose one owner.
5. **Play the request back in plain language.** Say what you understood, what you are unsure about, and what will change.
6. **Ask only questions that change scope.** Do not interview for things you can decide safely. When you do ask, explain the consequence of each option.
7. **Lock decisions in a table before planning.** If a decision removes a capability, say so explicitly.
   - Example: “Making all labels read-only means administrators can no longer rename standard columns.”

Good understanding prevents most rework. A wrong assumption is more expensive than one good question.

---

## 4. How to plan

Start from `docs/PLAN_TEMPLATE.md`. The plan must be self-contained enough for a fresh session with no chat history.

Required sections:

- Goal
- Locked decisions
- Current state and pain points
- Target UX
- Data and backend contract
- Shared helpers / new modules
- File-by-file implementation steps
- Tests: feature first, then model, then request
- Documentation updates
- Verification commands and manual smoke test
- Risks and notes
- Out of scope
- Definition of done

Rules:

- Name exact files, methods, and data shapes.
- Flag data consequences: lazy normalization, preserved data, migrations, slot history.
- Include tests for the happy path, empty state, invalid input, and persistence.
- Include the manual smoke test, not just the test suite.
- Make “out of scope” explicit to prevent scope creep.
- If the plan grows too large, split it rather than hiding complexity.
- Update the plan when a decision changes. A stale plan is worse than no plan.

A strong plan lets another agent implement without re-discovering the domain.

---

## 5. UI/UX principles

### 5.1 Hide the machinery

- Never show raw keys, internal IDs, JSON, or storage slot names to normal users.
- Never ask a user to type JSON in a normal form.
- If a value is derived, show the meaning, not the derivation.
- Technical detail belongs on developer/debug surfaces only.

### 5.2 Type-first creation

- Ask what the data means, not which database column to use.
- The system assigns storage slots, keys, and internal identifiers.
- Offer friendly types:
  - Text
  - Whole number
  - Decimal number
  - Yes / No
  - Date & time
  - Choice list
- Keep the storage mapping invisible but rigorous underneath.

### 5.3 One owner per concept

- A label has one home.
- A type has one home.
- A layout setting has one home.
- If another page owns a field, render it read-only here with a source badge and a link.
- Do not let two pages compete for the same value.
- Do not make a field editable just because the current page happens to receive it.

### 5.4 Progressive disclosure

- Keep the main row scannable: name, type, summary, actions.
- Put complex configuration in an expandable panel below the row.
- Do not put ten controls inside a table cell.
- One panel open at a time is usually enough.
- The summary tells the user what is configured; the panel lets them change it.
- Preserve the panel state across add/remove/reorder operations.

### 5.5 Explain everything

- Add a short help card at the top with a worked example.
- Add tooltips to every label, input, checkbox, badge, and icon-only button.
- Explain:
  - what the control does
  - what happens after Save
  - what happens when you delete
  - what Active/Inactive means
  - why a field is disabled
  - what data remains after removal
- Use plain language and examples, not schema language.
- Empty states should tell the user what to do next.
- Disabled controls should say why they are disabled.

### 5.6 Explicit actions

- A select must not auto-add or auto-submit on change.
- Use a clear **Add** button.
- Use a clear **Save** button; keep **Cancel** visible.
- Show that nothing is saved until Save is clicked.
- Separate “configure” from “save”.
- Avoid clever flows that complete an action on selection.

### 5.7 Protect the user

- Block removal of structurally required fields.
- Warn that deleting a configuration does not delete the underlying data.
- Separate “remove from this view” from “delete the data”.
- Use disabled states with reasons, not silent no-ops.
- Require confirmation for destructive actions that cannot be undone.

### 5.8 Validate before submit

- Mirror server rules on the client.
- On invalid input: show a toast, focus the first invalid field, and stay on the page.
- Never let a server redirect destroy unsaved edits for a predictable validation error.
- Keep the server as the final authority for edge cases.
- Prefer native form submission after client validation when the backend redirects on success.

### 5.9 Keep it scannable and accessible

- Fewer columns, fewer controls, one obvious next action.
- Prefer icons + text over icon-only actions.
- Use up/down buttons over drag-and-drop when ordering is needed.
- Use semantic color tokens only; never raw palette classes or `dark:` variants.
- Every group needs a border or distinct background.
- Keep mobile layouts usable with horizontal scroll or stacked cards.
- Focus the new/edited row after an action so the user does not lose their place.

### 5.10 Consistent patterns

- Reuse the same interaction pattern across pages.
- A “Setup” / “Configure” panel should behave the same everywhere.
- A summary row + expandable detail is a house pattern.
- A source badge + lock icon is the house pattern for read-only fields.
- Use the same type labels and icons everywhere through shared helpers.

### 5.11 Tradeoffs we make

These are deliberate defaults, not accidents:

- **Progressive disclosure over density.** A summary row plus an expandable panel beats a table cell with ten controls.
- **Up/down over drag-and-drop.** Simpler, accessible, testable, and enough for column ordering.
- **Native form submit plus client validation over rewriting to JSON.** Keep the existing redirect/flash flow unless the page already works another way.
- **Metadata over new database columns.** If the existing shape can carry the configuration, use it.
- **Lazy normalization over destructive migrations.** Correct on next save; add a backfill only when immediate consistency is required.
- **Model-level canonicalization over controller-only rules.** If several writers exist, enforce the invariant at the model layer.
- **One shared helper over three local copies.** Type labels, names, and summaries must not drift.
- **Explicit actions over clever automation.** A select should not silently add or submit.
- **Fewer controls over feature density.** Remove a control before adding another explanation for it.
- **Text plus icon over icon-only.** Use a tooltip when an icon must stand alone.

---

## 6. Frontend mechanics

### 6.1 Shared domain helpers

- Put type labels, icons, names, summaries, and option lists in a shared helper module.
- One source of truth for frontend display rules.
- Do not duplicate type maps across controllers.
- Use `translate()` inside the helper or return translation keys.
- A helper that returns user-facing text must be the only place that text is assembled.

### 6.2 State and rerenders

- Keep editable state in arrays/objects on the controller.
- Before any rerender or reorder, call `captureDOMState()` to read current input values back into state.
- Use stable `data-key` attributes, not array indices, to identify rows across rerenders.
- Reindex hidden input names after add/remove/move.
- Focus and scroll to the new/edited row after rerender.
- Rerender only the section that changed when the whole page does not need it; capture state first either way.

### 6.3 Native form submission with hidden panels

- If the backend redirects on success, keep native form submission.
- Render every settings panel in the DOM, even when visually collapsed (`hidden` class).
- Hidden inputs still submit; unmounted inputs do not.
- Add a JavaScript `handleSubmit` only to validate, then call `event.target.submit()`.
- Do not replace a redirect-based form with a JSON endpoint unless the page already works that way.

### 6.4 Empty collections

- When a form can clear a collection, add a hidden marker such as `columns_submitted=1` or `properties_submitted=1`.
- In the controller, treat the marker + no nested params as an intentional empty array.
- Without this, Rails leaves the old collection in place.
- This is especially important when the UI allows removing the last row.

### 6.5 Safety and correctness

- Escape every dynamic value with `escapeHtml`.
- Use the project `form()` helper and `fetchJson()`.
- Do not use native `fetch()` or raw `<form>` tags.
- Use `tooltip()` for all explanatory text.
- Use `translate()` for every string; add the Vietnamese dictionary entry in the same change.
- Do not interpolate unescaped user data into `innerHTML`.
- Do not add raw color classes; use semantic tokens.

### 6.6 Visual discipline

- Semantic tokens: `bg-card`, `text-foreground`, `text-muted-foreground`, `border-line`, `bg-muted`, `bg-primary`, `text-danger`, etc.
- No raw palette classes.
- No `dark:` variants on themed colors.
- Group with borders or distinct backgrounds.
- Keep the main table width under control; move complexity into panels.
- Use Material Symbols already available in the app.
- Prefer a clean, quiet layout over decorative density.

### 6.7 Code style

- **Controllers read like a sequence of intentions:** hydrate → render → capture → validate → mutate → rerender.
- **Split HTML builders into small named methods:** row, panel, summary, add area, empty state. A 600-line `contentHTML()` is a warning sign.
- **Keep DOM reads, state mutation, and rerender separate.** `captureDOMState()` should not also rebuild the page.
- **Use plain arrays/objects for UI state and JSDoc them.** Avoid hidden state on the DOM.
- **Names explain what; comments explain why.** Do not narrate obvious code.
- **Prefer explicit code over clever abstractions.** A small helper with a clear name beats a generic engine.
- **Add no new dependencies when an existing helper or native API will do.**
- **Backend normalization lives in small private methods with named constants.** Do not bury a 30-line transformation in `update`.
- **Put invariants in the model when multiple writers exist; put form-shape normalization in the controller.**
- **Error messages should say exactly what failed and how to fix it.**
- **Escape dynamic data at the render site.** Do not trust server data in templates.

---

## 7. Backend and data principles

### 7.1 The database contract is the source of truth

- UI types map to storage types.
- Example: a choice list is an integer column with an input type of `select` and an options array — not a new database type.
- Prefer metadata over schema changes when the shape is already supported.
- Keep the stored shape stable for consumers: search, filters, reports, and integrations.

### 7.2 One canonical source per derived value

- If a label is owned elsewhere, derive it at the model layer.
- Use a `before_validation` normalizer when the UI is read-only, so UI, API, seeds, and callbacks all agree.
- Do not rely on the controller alone; background callbacks and imports save models directly.
- Normalize names on every save, not just when the editor is used.

### 7.3 Normalize form shapes in the controller

- Convert indexed form hashes into arrays.
- Coerce booleans, integers, decimals, and nulls.
- Drop fully blank nested rows.
- Keep the stored shape stable for consumers.
- Preserve metadata keys the form does not own; merge, do not replace.
- Strip blank optional settings, but keep meaningful falsy values such as `false` and `0`.

### 7.4 No destructive migrations for UX work

- Prefer lazy normalization on next save.
- Add an optional backfill task only when immediate consistency is required.
- Never silently delete data to make a UI cleaner.
- If existing data must change, say so in the plan and make the migration reversible or idempotent.

### 7.5 Protect data integrity

- Track used storage slots when deletion could cause old data to appear under a new label.
- Keep audit logs for configuration changes.
- Touch the parent company when the change affects client-cached data.
- Do not reuse a slot unless you are certain the old data cannot surface.

### 7.6 Error contracts

- JSON endpoints: `{ errors: [...] }` with `:unprocessable_content`.
- HTML form flows: redirect with flash and preserve the server as final validator.
- Client validation should mirror, not replace, server validation.
- Messages should describe the exact action that failed or completed.

---

## 8. Testing and verification

Priority order:

1. Feature specs — the user-facing proof
2. Model specs
3. Request specs

Rules:

- Update existing specs that encode the old UX; do not delete coverage without a replacement.
- Add paired success/failure cases for validation.
- Test empty states, disabled states, reordering, persistence, and invalid input.
- Test that clearing all rows actually saves.
- Test that hidden panel inputs still submit.
- Run `bundle exec parallel_rspec -n 14 <paths>`; never bare `parallel_rspec` or single-process RSpec for verification.
- Run `bin/rubocop`, `bin/check_colors --strict`, and `bin/brakeman`.
- Run a translation coverage check for new `translate()` keys.
- Manual smoke test: happy path, empty state, invalid input, reload persistence, and the live consumer page.

A passing request spec is not proof when a feature spec exists or should exist.

### 8.1 Read it like a manager before declaring done

Open the finished page and ask:

- Can I tell what each row means without opening the code?
- Do I know what Save will do?
- Do I know what happens if I remove this?
- Can I undo a mistake before saving?
- Does the empty state tell me what to do next?
- Does the live consumer page actually change?
- Is the next action obvious without reading a tooltip?

If the answer is “no” to any of these, the page is not done yet.

> The `AGENTS.md` pre-commit checklist still applies in full: credit deduction, constants, client cache, language, metadata editing, semantic colors, grouping, and BE↔FE link comments.

---

## 9. Definition of done

- [ ] The user-facing surface has no raw keys, internal IDs, or JSON.
- [ ] One owner per concept; read-only fields show their source.
- [ ] Complex settings live in an expandable panel, not a cramped table cell.
- [ ] Every control has a tooltip, help text, or example.
- [ ] Add/remove/save actions are explicit.
- [ ] Client validation prevents predictable server redirects.
- [ ] Empty collections save correctly.
- [ ] Derived names/types are normalized at the model layer.
- [ ] Shared helpers and dictionary entries are in place.
- [ ] Feature specs pass; model/request specs pass.
- [ ] Lint, colors, and security scans are clean.
- [ ] Docs are updated.
- [ ] Out-of-scope items are documented.

---

## 10. Anti-patterns

- Showing storage keys such as `property_string_1` or `extra_123` to normal users.
- Raw JSON textareas in a user-facing form.
- Auto-adding or auto-submitting on select change.
- Ten controls in one table cell.
- Editable labels on a page that does not own them.
- Server-only validation that loses unsaved edits.
- Duplicated type maps or hardcoded user-facing strings.
- Raw palette classes or `dark:` variants.
- Drag-and-drop when up/down buttons are enough.
- Destructive migrations for a presentation change.
- Claiming completion on request/model specs alone.
- Hiding a disabled control’s reason.
- Leaving an empty state that does not say what to do next.

---

## 11. Canonical plan shape

Use `docs/PLAN_TEMPLATE.md`.

A plan is not a wish list. It is an executable contract:

- decisions are locked
- the data contract is explicit
- each file change is named
- each test is named
- the verification command is named
- the out-of-scope list prevents drift
- the definition of done is binary

Write it for a fresh session, not for the current conversation.
