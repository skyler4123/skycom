# <Feature / Refactor> — Implementation Plan

> Copy this template into the plan location the team uses. Fill every section.
> Keep it self-contained: a fresh session with no chat history must be able to execute it.
> Update it when a decision changes.
> If any decision is still open, resolve it before filling the rest. Do not hand over a plan with unresolved scope.

---

## 1. Goal

<One paragraph. What user problem are we solving? What will feel different when this is done?>

---

## 2. Locked decisions

| Decision | Choice |
|---|---|
| <decision> | <choice> |
| <decision> | <choice> |

> If a decision removes an existing capability, state the consequence explicitly.

---

## 3. Current state

### 3.1 Files

| File | Current role |
|---|---|
| `<path>` | <what it does today> |
| `<path>` | <what it does today> |

### 3.2 Pain points

- <what is wrong today>
- <what confuses users>
- <what breaks or loses data>

---

## 4. Target UX / behavior

### 4.1 <Page / section>

- <what the user sees>
- <what the user can do>
- <empty state>
- <disabled state>
- <error state>
- <tooltips / help text / examples>

### 4.2 <Next section>

- <same detail>

---

## 5. Data and backend contract

- <stored shape>
- <required keys>
- <validation rules>
- <normalization rules>
- <what is preserved from existing metadata>
- <what is intentionally not changed>

Include a JSON/Ruby example when the shape is non-obvious.

---

## 6. Shared helpers / new modules

| Helper / module | Responsibility |
|---|---|
| `<name>` | <type labels, names, summaries, options> |

- <what is the single source of truth>
- <what is exported and reused>
- <what is intentionally local to one controller>

---

## 7. Implementation steps

### Step 1 — <name>

1. <file change>
2. <file change>
3. <test/doc change>

### Step 2 — <name>

1. <file change>
2. <file change>

### Step 3 — <name>

1. <file change>
2. <file change>

> Keep steps small enough that another agent can execute them in order.

---

## 8. Tests

### Feature specs (primary proof)

- <happy path>
- <empty state>
- <invalid input>
- <persistence after reload>
- <live consumer page reflects the change>

### Model specs

- <valid case>
- <invalid case + error contract>
- <normalization case>

### Request specs

- <controller normalization>
- <empty collection marker>
- <canonical value enforcement>

> Feature specs are the most important. Do not declare done on request/model specs alone.

---

## 9. Documentation

- `docs/<doc>.md` — <what changes>
- `docs/MODEL_CALLBACKS.md` — <only if callbacks changed>
- `docs/LANGUAGE.md` / dictionary — <new user-facing strings>

---

## 10. Verification

```bash
bundle exec parallel_rspec -n 14 <feature spec paths>
bundle exec parallel_rspec -n 14 <model spec paths>
bundle exec parallel_rspec -n 14 <request spec paths>
bin/rubocop
bin/check_colors --strict
bin/brakeman --no-pager
```

Manual smoke test:

1. <open the page>
2. <add something>
3. <configure something>
4. <save>
5. <reload and verify persistence>
6. <verify the live consumer page>
7. <try invalid input and confirm the toast/stay-on-page behavior>

---

## 11. Risks / notes

- <data consequence>
- <lazy normalization or migration note>
- <what could regress>
- <what is intentionally preserved>
- <performance or cache note>

---

## 12. Out of scope

- <page / feature not changed>
- <behavior intentionally left alone>
- <future follow-up>

---

## 13. Definition of done

- [ ] <user-facing outcome>
- [ ] <no raw keys / IDs / JSON>
- [ ] <one owner per concept>
- [ ] <validation behavior>
- [ ] <empty collection behavior>
- [ ] <feature specs green>
- [ ] <model specs green>
- [ ] <request specs green>
- [ ] <rubocop / check_colors / brakeman clean>
- [ ] <docs updated>
- [ ] <out-of-scope items documented>
