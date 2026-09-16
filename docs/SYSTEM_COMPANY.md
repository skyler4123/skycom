# Skycom System Company

> **Status**: Live (2026-09-17). Every `System` record automatically owns a dedicated
> `Company` ("system company") — created by the `System#ensure_company!` callback
> and detected via `Company#system_company?`. The `System` model remains the core
> authority for platform identity; the system company is the *operational* face
> of the platform inside normal business flows.

---

## 1. Overview

| Concept | Model | Meaning |
|---------|-------|---------|
| `System` | `app/models/system.rb` | Platform identity records (`system_global`, `system_us`, `system_vn`). The **core authority** — permanent, unique code, identity-change and destruction prevented. |
| System company | `Company` (`business_type: :system`) | The operational face of a `System` — a **real, first-class `Company`** owned by a dedicated `super_admin` user (`<code>@system.com`) |
| `Company#system_company?` | derived predicate | `System.where(company_id: id).exists?` — truth comes from the FK, never a flag |
| `Company.system_companies` | scope | All system-owned companies (for platform services that need to find them) |

One `Company` per `System` record — guaranteed by a callback, not by convention:

```
System.create! (before_create :ensure_company!)
  ├─ find_or_create dedicated user (system_vn@system.com, super_admin, random password)
  ├─ Company.new(business_type: :system).tap { |c| c.system_owned = true }.save!
  │     └─ initialize_company → owner records ONLY (see §4)
  └─ systems.company_id set in the same INSERT (single save transaction)
```

---

## 2. Why System Companies Exist

Some external services work at **one level**, but Skycom must apply them to
**two flows**:

| Flow | Direction | Example |
|------|-----------|---------|
| **B2C** | End-user ↔ Company | A customer chatting with a store's support account |
| **B2B** | Company ↔ Skycom | A store chatting with Skycom's help-desk when they need help |

Chat & Help Desk is the first such service (sidebar group `chat_help_desk`), and
the pattern is open to any other single-level service (notifications, system
demo data, platform-owned catalogs).

If the "Skycom side" of these flows were a special construct, every query, UI
screen, permission check, and association would need a parallel system-flavored
path. Instead, Skycom's own side is modeled as a **regular `Company`** — a
system company. That makes the platform a peer at the same level as every other
company:

- Chat accounts live on the system company as ordinary `Employee` records.
- Conversations, memberships, dashboards, and ABAC permissions work with zero
  special-casing — the system side is "just another company".
- Discovery is one scope away: `Company.system_companies`, or
  `System.find_by(code: "system_vn").company` for a specific region.

---

## 3. Security Model — `System` Stays the Core

The system company exists for *operational convenience*, never for *identity*.
A tenant must never be able to make its company look like the system's company.
The design defends against that at the model/DB level:

| Defense | Mechanism |
|---------|-----------|
| **Systemness is not a company attribute** | `system_company?` is **derived** from the `systems.company_id` FK — `System.where(company_id: id).exists?`. There is no persisted boolean, enum value, or metadata key on `companies` that marks a company as system-owned. A company changing its own `business_type`, `metadata`, or any other attribute can never fake it — the FK row lives in another table it does not own. |
| **Only the callback writes the link** | `systems.company_id` is set exclusively by `System#ensure_company!` (plus the seed heal step, which calls the same method). No controller, service, or company-facing path assigns a company to a `System`. |
| **`system_owned` is creation-time-only** | `Company#system_owned` is an `attr_accessor`, never persisted. It exists only so `initialize_company` can shape the new company during creation (owner records only, no owner-role demotion). It cannot be smuggled through params to alter a persisted company's behavior — nothing reads it after creation. |
| **`System` rows are protected** | Unique `code` and `name` indexes; `validate :prevent_identity_changes` blocks code/name edits; `before_destroy :prevent_destruction` blocks deletion. The seed wipes companies/users but preserves `System` rows and heals links (`System.find_each(&:ensure_company!)`). |
| **No reverse association** | `Company` deliberately has **no** `has_one :system`. Without a company-side association, company-facing code cannot traverse into, eager-load, or mutate system identity — discovery is a read-only query on the FK. |

> **Invariant**: a company is a system company if and only if a `System` row
> points at it. Anything else claiming system-ness is a bug.

---

## 4. Architecture Summary

### Creation (the callback)

`System#ensure_company!` runs on `before_create`, so user + company are created
inside the System's own save transaction and `company_id` is populated in the
same INSERT (no dangling row, no second write). The company is saved **before**
assignment — assigning an unsaved `belongs_to` target would snapshot
`company_id` as `nil`.

### The "owner records only" init profile

`Company#initialize_company` ORs the creation-time `system_owned` flag into its
existing guards (`unless self.class.skip_init || system_owned`):

| Init step | System company |
|-----------|----------------|
| Retail/Hospital seed (~600 policies, ~40 categories) | ❌ skipped |
| `setup_payment_method_appointments` | ❌ skipped |
| Owner Role / Policy / Employee / RoleAppointment | ✅ created |
| `user.system_role` demotion to `company_owner` | ❌ skipped (owner stays `super_admin`) |
| Wallet (`main_credit_balance: 0`) | ✅ created |
| Default Setting (sidebar config) | ✅ created |

The dedicated owner user keeps `system_role: :super_admin` (platform staff —
`accessible_companies` returns all companies, which fits a future support
account). Company `country`/`currency` are mapped from the System's
(`global → us/usd`) via the single-file constants
`System::SYSTEM_COMPANY_COUNTRIES` / `SYSTEM_COMPANY_CURRENCIES`; an unmapped
value falls back to the `Company` enum defaults.

### Seed resilience

Reseeding wipes all companies/users but preserves `System` rows. One line in
`Seed::ApplicationService` repairs the dangling links after the wipe:

```ruby
System.find_each(&:ensure_company!)
```

`ensure_company!` is idempotent (early return when a company is already
linked), so the same method backs the callback, the heal step, and any manual
repair.

---

## 5. Using System Companies

```ruby
# Any system company (chat feature will scope accounts to these)
Company.system_companies

# A specific region's platform side
System.find_by(code: "system_vn").company

# Predicate — true iff a System row points at this company
company.system_company?
```

The system company is a normal `Company` everywhere else: it can own
employees, hold wallet credits, appear in admin listings (filter via
`system_companies` when system rows should be excluded), and participate in
ABAC like any tenant.

---

## 6. File Reference

| File | Purpose |
|------|---------|
| `app/models/system.rb` | `belongs_to :company`, `before_create :ensure_company!`, country/currency mapping constants, `find_or_create_system_user!` |
| `app/models/company.rb` | `system_owned` accessor, `business_type: :system` enum, `system_company?`, `system_companies` scope, `initialize_company` guards |
| `app/services/seed/application_service.rb` | `System.find_each(&:ensure_company!)` heal line after the System seed block |
| `app/services/seed/company_service.rb` | Random business-type sample excludes `"system"` |
| `spec/models/system_spec.rb` | Callback, country/currency mapping, idempotency, seed-heal coverage |
| `spec/models/company_spec.rb` | `system_owned` init guards, role-demotion controls, detection API |
| `db/migrate/20251110100460_create_systems.rb` | `systems.company_id` (nullable FK, indexed) |
| `docs/MODEL_CALLBACKS.md` | Callback reference (System + Company rows) |
| `docs/superpowers/specs/2026-09-17-system-company-design.md` | Full design spec (uncommitted, gitignored) |

---

*See also: `docs/MODEL_CALLBACKS.md` (callback reference), `docs/ROADMAP.md`
(Chat & Help Desk — future work that will host its accounts on the system
company).*
