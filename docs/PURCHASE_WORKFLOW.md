# Skycom Purchase Process & Workflow Engine

> **Status**: Live (2026-09-18). Backend-first: models, migrations, seed, specs. Dashboards + advance API come next.
> **One permission rule to remember**: a workflow transition requires **update permission on the subject** — `employee.can?(:update, subject)`. ABAC is Skycom's **only** permission system; there is no per-step role mechanism.

---

## 1. Overview — The Buy Process (Jira-style)

An employee needs to buy things for the company (e.g. more pens). She raises a **Purchase** — a ticket.
The ticket moves through phases like a Jira issue: **pending → approved → bought → done**. Anyone with
update permission on the Purchase can transition it, exactly like anyone in a Jira project can move a
ticket. Every transition leaves a permanent audit row (`WorkflowStepLog`), so no extra role machinery
is needed to know *who did what*.

```
Employee creates "Buy office supplies"
        │  Purchase created → workflow auto-bound → status: pending
        │  100 pens × $1  (PurchaseItemAppointment = source of truth)
        ▼
Submit (step 1) ── approved ──► Manager Approval (step 2) ── approved ──► Buy (step 3) ── approved ──► Complete (step 4)
        │                             │                                     │                        │
        │                             ├── rejected ──► status: cancelled    │                        └─ approved on last step
        │                             └── rework ──► back to any earlier step                        → status: completed
        ▼
  Total price always computed live from appointments (100 × $1 = 100)
```

**Stock bridge (2026-09-23)** — a completed Purchase lands its goods through the stock services
(never direct writes): final workflow approval triggers `StockMovementService::Purchases::CompleteService`
inside the advance transaction → generates a received `StockImport` (lines reference the destination
warehouse's `Stock` rows via `StockItemAppointment`) → `add` `StockTransaction` rows increase quantities
through the hardened ledger callback. Requires `purchases.warehouse_id` (destination) and
`purchase_items.product_id` (optional — item-less/product-less lines skip the bridge). See
`docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md` §4.

## 2. The Permission Model (single system — ABAC)

| Rule | Detail |
|------|--------|
| **Source of truth** | ABAC (`docs/ABAC.md`) — `Employee#can?` with policies + tag conditions + owner bypass |
| **Transition rule** | `Workflows::AdvanceService` refuses any transition unless `employee.can?(:update, subject)` (instance-level check — tag conditions evaluated per record) |
| **Per-step roles** | ❌ Removed by design. Step *names* carry the semantics ("Manager Approval") but enforcement is plain ABAC, mimicking Jira's "anyone in the project can move the ticket" |
| **Audit** | `WorkflowStepLog` records actor, step, outcome, note, from/target steps — this is why step-level permission customization is unnecessary |
| **Future API layer** | When controllers land, the Pundit policy (`Companies::PurchasesPolicy#update?` → `record.can?(:update, Purchase)`) calls the **same** `can?` — still one system, defense in depth only |

The generic engine rule for any future process (e.g. Attendance `leave_process`): *transitioning a
subject's workflow requires update permission on that subject*.

## 3. Category Is the Bridge (binding source of truth)

Subjects **never link to a Workflow directly**. The **Category** is the bridge and the single source
of truth for workflow binding — mirroring how Category already owns the dynamic schema
(`docs/CATEGORY_DYNAMIC_SCHEMA.md`):

```
Category ──► PropertyMapping   (what property_* slots mean)
Category ──► TableConfig       (which columns are visible)
Category ──► Workflow          (which process the records follow)   ← the new bridge
```

| Rule | Detail |
|------|--------|
| **One workflow per category** | Enforced by a **unique index on `workflows.category_id`** — DB-level, same category ⇒ same workflow, always |
| **Resolution** | `Category#default_workflow` (first workflow of the category) — mirrors `default_property_mapping` / `default_table_config` |
| **Purchase carries only the pointer** | `purchases.workflow_step_id` is the subject's current-step pointer — there is **no** `purchases.workflow_id`; the workflow is always derived via the category |
| **No default flag** | `workflows.is_default` was removed — the category *is* the selector; different categories may follow different processes (e.g. "Office Supplies" → 4-step standard flow) |
| **Draft fallback** | A purchase whose category has no workflow (or whose workflow has no steps) stays `draft` |
| **Company consistency** | `Workflow` validates its category belongs to the same company |

## 4. Data Model

All six tables are company-scoped, UUIDv7, and carry the standard System Fields block
(`docs/ARCHITECTURE_GUIDES.md`).

| Model | Table | One purpose |
|-------|-------|-------------|
| `Purchase` | `purchases` | The buy ticket (dynamic model — Order clone + extras) |
| `PurchaseItem` | `purchase_items` | The reference item ("Ballpoint pen") |
| `PurchaseItemAppointment` | `purchase_item_appointments` | The line item — **source of truth** for quantity/price |
| `Workflow` | `workflows` | A generic process template (purchase_process, leave_process, ...) |
| `WorkflowStep` | `workflow_steps` | An ordered step in a template |
| `WorkflowStepLog` | `workflow_step_logs` | Audit + transition record per subject |

### Relationships

```
Category 1─1 Workflow (unique index on workflows.category_id — the bridge)
Workflow 1─* WorkflowStep (ordered by position)
Workflow 1─* WorkflowStepLog
Purchase ──► category ──► Workflow   (derived — no direct Purchase↔Workflow FK)
Purchase ─── workflow_step_id ──► WorkflowStep   (the subject's current-step pointer)
Purchase 1─* WorkflowStepLog   (polymorphic subject)
PurchaseItem 1─* PurchaseItemAppointment (anchor — SetDefaultCompanyConcern derives company)
Purchase 1─* PurchaseItemAppointment      (as: :appoint_to)
Purchase ──► supplier (optional), branch (optional)
```

### Column notes

| Model | Key columns |
|-------|------------|
| `Purchase` | Order clone **minus** `customer_id`/`email`/`phone_number`; **plus** `supplier_id`, `needed_by`, `workflow_step_id` (current-step pointer only — no workflow_id); 60 `property_*` slots; `business_type: { office_supply: 0, equipment: 1, service: 2 }` |
| `PurchaseItem` | `name`, `description`, `code`, `unit` ("piece"/"box"), `estimated_unit_price` (**reference only**), 60 `property_*` slots |
| `PurchaseItemAppointment` | `purchase_item_id` + polymorphic `appoint_to` (→ Purchase) + `quantity` / `unit_price` / `total_price` |
| `Workflow` | `category_id` (**unique — one workflow per category**), `name`, `process_type: { purchase_process: 0, leave_process: 1 }` — no `is_default` column |
| `WorkflowStep` | `name`, `position` (unique per workflow) — **no permission columns** |
| `WorkflowStepLog` | `subject` (polymorphic), `employee_id` (actor), `outcome: { submitted: 0, approved: 1, rejected: 2, rework: 3 }`, `note`, `metadata` (`from_step_id`, `target_step_id`) |

## 5. State Machine — `Workflows::AdvanceService`

The **single write path** for workflow state. One transaction: authorize → write log → move pointer → sync status.

```ruby
Workflows::AdvanceService.call(subject:, employee:, outcome:, note: nil, target_step: nil)
# => { success: true } | { success: false, errors: ["..."] }   # plural `errors` per docs/API_ERROR_FORMAT.md
```

| Outcome | Behavior |
|---------|----------|
| `submitted` | ❌ Not allowed via advance — written automatically at creation |
| `approved` | Log → pointer to `next_step`; on the last step → subject `workflow_status: completed` (pointer stays at last step; the log is the audit) |
| `rejected` | Log → subject `workflow_status: cancelled`, workflow ends (pointer unchanged) |
| `rework` | Log → pointer to `target_step` (must belong to the same workflow) |

Guards in order: workflow bound → employee present → valid outcome → not completed/cancelled →
**`can?(:update, subject)`** → rework target rules.

### `workflow_status` mapping (reuses the generic `WORKFLOW_STATUS` constant)

| Event | Purchase.workflow_status |
|-------|--------------------------|
| Created with category workflow bound | `pending` |
| Created with no category workflow (or `skip_workflow`) | `draft` |
| Any non-final step approved | `confirmed` |
| Final step approved | `completed` |
| Any step rejected | `cancelled` |

### Purchase callbacks (the only new model callbacks — see `docs/MODEL_CALLBACKS.md`)

- `before_validation :bind_category_workflow, on: :create` — binds the **category's** default
  `purchase_process` workflow (first step + `pending`); skipped when the transient `skip_workflow`
  flag is set or the category has no workflow (or its workflow has no steps) → stays `draft`.
- `after_create :record_submission_log` — writes `WorkflowStepLog(outcome: :submitted)` when bound;
  actor comes from the transient `created_by_employee` accessor (the log row is the permanent record).
- `Workflow#before_destroy :release_subject_pointers` (**prepend: true** — must run before the
  `workflow_steps dependent: :destroy` hook) — FK safety for the step pointer.

### The pen example, end to end

```
Employee creates "Buy office supplies" (auto-bound, step 1 "Submit")
  └─ log: submitted / employee=her                       status: pending
She (or the manager — anyone with can?(:update, Purchase)) approves Submit
  └─ log: approved                                        status: confirmed → pointer "Manager Approval"
Approve "Manager Approval" → "Buy" → employee buys pens offline → approve "Buy" → "Complete" → approve
  └─ final approve                                        status: completed
OR approve → reject "Manager Approval"                    status: cancelled
OR approve → rework to "Submit"                           status: pending (rework loop)
```

`total_price` is always computed live from appointments — `Purchase#total_price` = `purchase_item_appointments.sum(:total_price)`.

## 6. Seeding

**Init (production — every new retail/hospital company):**
- Categories: `purchases` ("Office Supplies", "Equipment", "Procurement Services") and
  `purchase_items` ("Stationery", "Equipment Items", "Consumables") — hospital mirrors with
  medical-flavored names.
- `Company::DEFAULT_RESOURCE_NAMES` includes `Purchase` + `PurchaseItem` → auto CRUD policies
  (~8) via `create_all_crud_policies` — this is how `can?(:update, Purchase)` becomes grantable in the
  Permissions UI.
- **Role grants** (both init services): Admin + Manager get full CRUD on Purchase/PurchaseItem;
  Cashier/Seller (retail) and Receptionist (hospital) get create/read/update on Purchase (+ read on
  PurchaseItem) as requesters. Other roles stay ungranted — owners extend via the Permissions UI.
- `create_default_workflows` (both init services): one **"\<Category\> Purchase Process"**
  (`process_type: purchase_process`) per purchases category — e.g. "Office Supplies Purchase
  Process" — with steps Submit → Manager Approval → Buy → Complete. Same category ⇒ same workflow.

**Enrich (development only):** `Seed::PurchaseService` / `Seed::PurchaseItemService` /
`Seed::PurchaseItemAppointmentService` create sample items and purchases across every phase
(completed / rejected / reworked / pending) with realistic log chains. Requesters/advancers are
selected from employees who actually hold `can?(:update, Purchase)` — the seeded demo respects the
ABAC permission model.

## 7. Extending to Another Process (e.g. Attendance leave_process)

1. Add the enum value: `Workflow.process_type` += `leave_process: 2` (inline enum — extend in place).
2. Make the subject model follow the Purchase pattern: `belongs_to :workflow_step, optional` +
   `has_many :workflow_step_logs, as: :subject` + a bind-on-create callback that resolves the
   subject's **category's** workflow (see `Purchase#bind_category_workflow`).
3. Seed a workflow per relevant category for that process type (the category is the bridge).
4. Transitions work immediately through `Workflows::AdvanceService` — permission stays
   `can?(:update, subject)`, audit stays `WorkflowStepLog`.

## 8. Design Tenets

1. **One permission system.** ABAC `can?` is the only authorization check in the whole flow. Do not reintroduce per-step roles, approval matrices, or parallel ACLs.
2. **Jira-style simplicity.** Ticket status may be changed by anyone who can update the ticket. Complexity lives in the *workflow template* (steps, order), not in per-step authorization.
3. **The log is the audit.** `WorkflowStepLog` answers who/what/when/why — `metadata.from_step_id`/`target_step_id` reconstruct the exact transition.
4. **The category is the binding.** Same category ⇒ same workflow, enforced by a unique index. Subjects carry only the step pointer — never a workflow_id.
5. **The appointment is the truth.** Line economics live on `PurchaseItemAppointment`; `PurchaseItem` is a reusable reference (`estimated_unit_price` is advisory).
6. **Stock goes through the services.** A completed purchase lands its goods via `StockMovementService::Purchases::CompleteService` (2026-09-23) — `StockImport` + `StockTransaction` ledger rows inside the advance transaction, never direct stock writes.

## 9. File Reference

| File | Purpose |
|------|---------|
| `app/models/purchase.rb` | Buy ticket — category-workflow binding callbacks + `total_price` |
| `app/models/purchase_item.rb` | Reference item (dynamic model) |
| `app/models/purchase_item_appointment.rb` | Line item + company derivation + same-company validation |
| `app/models/workflow.rb` | Process template — category binding (unique per category), `release_subject_pointers` |
| `app/models/workflow_step.rb` | Ordered step — `next_step` / `previous_step` |
| `app/models/workflow_step_log.rb` | Audit log — `outcome` enum, `store_accessor` metadata |
| `app/services/workflows/advance_service.rb` | The transition engine (permission rule documented in header) |
| `app/services/seed/{workflow,workflow_step,purchase,purchase_item,purchase_item_appointment}_service.rb` | Seed services |
| `app/services/seed/{retail,hospital}_init_service.rb` | `create_default_workflows` + categories + role grants |
| `app/services/seed/{retail,hospital}_enrich_service.rb` | Sample purchases across all phases (permission-aware requesters) |
| `spec/services/workflows/advance_service_spec.rb` | State machine + ABAC authorization coverage |
| `app/controllers/companies/purchases_controller.rb` | Purchases dashboard API (Shell-First) — dynamic search/filter index, line-item nested attributes, `POST advance` → `Workflows::AdvanceService` |
| `app/controllers/companies/workflows_controller.rb` | Workflows dashboard API — full REST CRUD, nested steps, category binding (one workflow per category) |
| `app/policies/companies/{purchases,workflows}_policy.rb` | Pundit policies (auto-derived by `Companies::Authorizable`; `advance?` = update permission) |
| `app/services/purchases/search_query_service.rb` | Purchases index search/filter (Meilisearch via `DynamicSearch::BaseQueryService`) |
| `app/javascript/controllers/companies/purchases/{index,new,show,edit}_controller.js` | Purchases dashboards (dynamic table, line-item rows, Jira-style Approve/Reject/Rework) |
| `app/javascript/controllers/companies/workflows/{index,new,show,edit}_controller.js` | Workflows dashboards (static CRUD + step row editor) |
| `spec/requests/companies/{purchases,workflows}_controller_spec.rb` | Request specs — dynamic search contract, advance endpoint, CRUD + default demotion |
| `spec/features/companies/purchases/{index,new,show,edit}_spec.rb` | Purchases E2E — dynamic table, line items, advance flows |
| `spec/features/companies/workflows/{index,new,show,edit}_spec.rb` | Workflows E2E — CRUD + default demotion |
| `docs/ABAC.md` | The permission engine (`can?`, policies, tag conditions, owner bypass) |
| `db/migrate/20260918000001..000006` | The 6 migrations |

---

*See also: `docs/ABAC.md` (permission engine), `docs/MODEL_CALLBACKS.md` (Purchase/Workflow callbacks),
`docs/DYNAMIC_TABLE.md` §2.5 (dynamic search/filter), `docs/ROADMAP.md`.*
