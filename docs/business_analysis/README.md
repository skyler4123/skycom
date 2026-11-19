# Skycom — Business Analysis

> **Purpose:** a plain-language record of what each Operation page and dashboard
> actually does today, written so a business analyst can decide what to finish,
> what to cut, and what to build next — without reading code.
>
> **Audience:** a person, a team, or an AI assistant. Every document must stand
> alone for all three.
>
> **Status:** in progress — rows marked `—` in the index have not been audited yet.

---

## 1. How to use this folder

1. Read this page: the legend in §3 and the glossary in §5. Nothing else is
   assumed knowledge.
2. Open the page document you need from the index in §4.
3. Read §1–§8 of that document. They are business language: purpose, people,
   screen, controls, numbers, gaps, decisions, demo path.
4. Act on §7 — **Decisions for the BA**. Each entry has options and a
   consequence, so a decision can be made without asking an engineer.
5. §9 is the engineering appendix. It exists so an engineer can confirm a claim.
   It is not required reading for a business decision.

**What these documents are not:**

| Not this | Owned by |
|---|---|
| How to build a new Operation page | `docs/OPERATION_PAGES.md` |
| The app-wide list of missing features | `docs/TODO.md` |
| Mobile feature parity | `docs/MOBILE_FEATURE_MATRIX.md` |
| A design system or UI standard | `docs/STYLING_GUIDELINES.md` |

---

## 2. The three readers

| Reader | What they need | How the docs serve it |
|---|---|---|
| **A person** (owner, operator, consultant) | "Can I show this to a customer tomorrow?" | Ship-readiness verdict + safe demo path on every page |
| **A team** (design, sales, support) | "What does this page promise, and what is it missing?" | Control inventory with status badges, one row per button |
| **An AI assistant** | Enough context to plan work without the codebase | Stable IDs, explicit gaps with options, engineering appendix |

---

## 3. Status legend

### 3.1 Control status

| Badge | Name | Meaning | How it was verified |
|---|---|---|---|
| ✅ | Works | Clicking it does the real thing end to end | The handler reads or writes real records |
| 🟡 | Partial | It works, but with a limit (read-only, capped, missing a filter) | The limit is named in the inventory row |
| 🗑️ | Placeholder | Clicking it says "coming soon" or "not connected yet" | The handler only shows a toast |
| 💤 | Honest gap | The block is visible but says "Not connected" and explains why | It returns `available: false` or an empty state |
| ⛔ | Dead | Visible and clickable, and nothing happens at all | No handler, or a handler with no effect |
| 🚧 | Missing | The operator's job needs it; it is not on screen anywhere | Named in §6, not in §4 |
| 🔢 | Fabricated | Shows a plausible number that does not come from records | The value is a literal, an index, or an invented fallback |

### 3.2 Page verdict

| Verdict | Rule |
|---|---|
| 🟢 Shippable | No 🔢 or ⛔ anywhere on the page |
| 🟠 Shippable with gaps | Only 🗑️, 💤, 🚧 remain — nothing claims to be what it is not |
| 🔴 Not shippable | At least one 🔢 or ⛔ is visible to an end user |

### 3.3 Mapping to the mobile matrix

`docs/MOBILE_FEATURE_MATRIX.md` uses its own badges. They mean the same things:

| Here | There |
|---|---|
| ✅ | ✅ |
| 🟡 | 🟡 |
| 🚧 | 🚧 |
| 💤 | 💤 |
| ⛔ | ❓ (broken or stale) |
| 🗑️ / 🔢 | no equivalent — mobile tracks availability, not honesty |

---

## 4. Page index

| Doc | Surface | Verdict | Controls | Open decisions | Last audited |
|---|---|---|---|---|---|
| [00-app-overview](00-app-overview.md) | Whole application, module by module | — | — | — | — |
| [01-operations-landing](01-operations-landing.md) | Operations list, activation, config, roles | — | — | — | — |
| [02-pos](02-pos.md) | POS console (point of sale) | 🔴 | 29 | 10 | 2026-11-19 |
| [03-booking](03-booking.md) | Booking console (facilities and reservations) | 🔴 | 30 | 10 | 2026-11-19 |
| [04-reception](04-reception.md) | Reception console (visitors, parcels, rooms) | 🔴 | 45 | 9 | 2026-11-19 |
| [05-inventory](05-inventory.md) | Inventory console (warehouse) | — | — | — | — |
| [06-store-manager](06-store-manager.md) | Store Manager console | 🔴 | 28 | 11 | 2026-11-19 |
| [07-dashboard](07-dashboard.md) | Company dashboard | — | — | — | — |
| [08-analytics](08-analytics.md) | Analytics | — | — | — | — |

Counts will be filled as each page is audited. They are counts of interactive
controls (buttons, links, inputs, tabs), not of every element on the page.

---

## 5. Glossary

Domain terms used across these documents. One sentence each, business meaning
first. If a term is missing, add it here before using it elsewhere.

| Term | Meaning |
|---|---|
| **Company** | The tenant. Every record in Skycom belongs to exactly one company. |
| **Branch** | A selling or service location — shop, hotel front desk, clinic, office. |
| **Warehouse** | A stock-holding location. Physical stock belongs to a warehouse, not to a branch. |
| **Employee** | A person who signs in to the company; carries a role and a category. |
| **Customer** | A person or organisation the company sells to; may have memberships and extended profiles. |
| **Operation** | A deployable working surface keyed by **purpose** (POS, Booking, Reception, Inventory, Store Manager), never by industry. |
| **Operation type** | One of the five catalog entries above; a company receives all five when it is created. |
| **Appointment** | The row that switches one Operation on at one Branch or Warehouse, and carries that location's settings and roles. Not a calendar appointment. |
| **Operation config** | Company-wide settings for an Operation. A location appointment inherits them and may override some keys locally. |
| **Workflow status** | The stage of a record: draft, pending, confirmed, in progress, completed, paid, cancelled, refunded. |
| **Lifecycle status** | Whether a record is active, inactive, archived, or deleted. |
| **Category** | A tree node that classifies products, services, customers, employees and more; can carry its own extra fields. |
| **Dynamic property** | An extra field defined per category at runtime, so a company can add data without a new database column. |
| **Dynamic table** | A company-defined table view over a resource: which columns, which filters. |
| **Role** | A named bundle of access assigned to an employee. |
| **Policy** | A rule that grants or denies one action on one subject (for example, "cashier may create an order"). |
| **Permission** | The effective right produced by roles and policies; every request is checked against it. |
| **Event** | A single-purpose "who / what / when" record used for visits, bookings, stays and parcels; linked to other records through appointment rows. |
| **Facility** | A physical space — room, table, meeting room — that can be booked or occupied. |
| **Order** | A sale: its lines, totals, payment state and fulfilment state. |
| **Stock** | The quantity of one product in one warehouse. The single source of truth for what is on hand. |
| **Stock pending** | Units reserved by an unpaid order or a hold; not yet removed from on-hand quantity. |
| **Invoice** | The money document behind an order or purchase, carrying tax and payment state. |
| **Purchase** | Buying stock from a supplier; progresses through the workflow engine. |
| **Discount** | A single-use code generated in bulk under a campaign group, reserved at payment and consumed when the invoice is paid. |
| **Company credit** | The prepaid usage balance that pays for metered actions. |
| **Ticket** | A support conversation between the company and Skycom. |
| **KPI** | Employee performance score. Today it measures paid orders per employee. |
| **Exam** | A timed assessment built from the question bank and assigned to employees. |
| **Attendance month / day** | The monthly attendance summary and its per-day rows, derived from check-in logs. |
| **Payroll** | The per-employee monthly pay record. Skycom stores the figures; it does not calculate payroll formulas. |
| **Shift template** | A reusable definition of a working shift. |
| **Scheduled shift** | A shift template applied to an employee on a date. |
| **Import** | Owner-prepared CSV loaded into one allowlisted table, with a dry run and a rollback. |
| **Company migration** | Config-driven CSV ingestion into several business tables, approved by the owner after a dry run. |
| **Notification** | An in-app message to a user, with tags for filtering. |
| **Document / Folder** | Company file storage with access rules. |
| **Profile / SubProfile** | Extension buckets for per-domain employee or customer details that should not bloat the base record. |
| **Seed** | The initial data created for every new company — operations, roles, configs. |

---

## 6. Keeping these documents alive

These docs are only useful if they are true. The rules:

1. **Ship a change to a page → update its document in the same change.** A new
   button without an inventory row is a broken document.
2. **A new Operation type gets a document before it reaches a customer.**
3. **Never renumber an existing ID.** If a control disappears, keep the row and
   strike it through, so old decisions still make sense.
4. **Add a badge to the legend before using it.** One vocabulary, no exceptions.
5. **Re-audit when the verdict changes** — a page moving from 🔴 to 🟠 is news.
6. **Dates are part of the claim.** Update `Last audited` only after re-reading
   the code, never when merely editing wording.

---

## 7. Audit log

| Date | Scope | Change |
|---|---|---|
| 2026-11-19 | Folder | Created index, legend, glossary, and the page-document contract |
