# Operations landing and configuration

> **Last audited:** 2026-11-19 · **Audit scope:** operations index, operation
> configs index/show/edit, branch and warehouse appointment show/edit, launch
> service, policies, feature specs. No live browser run.
> **Ship readiness:** 🟠 shippable with gaps — no fabricated numbers and no dead
> controls, but one visible table defect and a configuration surface that edits
> less than its name promises.
> **Who this is for:** the company owner or administrator who decides which
> operations run at which location.
> **Mobile:** the operations list is mirrored on mobile; configuration is web-only.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [02-pos](02-pos.md), [03-booking](03-booking.md), [04-reception](04-reception.md),
> [05-inventory](05-inventory.md), [06-store-manager](06-store-manager.md)

---

## 1. What this page is for

This is the control room before any console: the list of operations switched on
at each branch and warehouse, the way to launch one, and the way to change who
may use it.

A company receives all five operations when it is created. This area answers:
*which location has which operation, is it active, who can open it, and what does
it inherit?*

"Done" means the right people at the right location can open the right console,
and nobody else can.

---

## 2. Who uses it

**The person:** the owner or an administrator setting up a branch or warehouse,
usually once at onboarding and occasionally when staff change.

**Their goal:** switch operations on or off per location and restrict each one to
the right roles.

**What they can do here today:**

- See every operation at every branch and warehouse in one table.
- Filter by name, type, status, and location.
- Launch an operation they are allowed to use.
- Open the appointment detail for a location.
- Edit the roles for a location (narrowing only).
- Activate or deactivate an operation at a location.
- Edit the company-wide roles for an operation.

**What they must do elsewhere:**

- Add or remove an operation type for the company — not possible in the UI.
- See what a role actually sees before saving — no preview.
- See who changed access and when — no audit trail.
- Bulk-change every location at once — one at a time only.

**Access:** any employee with read permission on Operations sees the list;
launching also requires the operation's role gate.

---

## 3. The screens, in words

### 3.1 Operations list (`/operations`)

A card containing a title and explanation, a four-field search form (Search,
Type, Status, Location) with a **Search** button, and a table with seven columns:
Operation, Type, Location, Resolution, Status, Access Roles, Actions.

Each row shows the operation name and code (a link to the location appointment),
type, location, a status badge, role chips, a launch icon, and an edit icon. The
launch icon is greyed out with a tooltip when the appointment is inactive or the
employee lacks access. Empty state: "No operations found."

### 3.2 Operation configs list (`/operation_configs`)

A card with a search form (Search, Type, Status), then a table: Operation, Type,
Access Roles, Status, Locations, Actions. Each row links to the config detail and
offers an edit icon.

### 3.3 Operation config detail and edit

Detail shows the name, code, status badge, type, location count, and role chips,
with **Edit Config**. Edit exposes only the company-wide **Access Roles** picker,
a warning that saving resets every branch and warehouse config, Cancel and Save.

### 3.4 Appointment detail and edit

Detail shows the operation, the branch or warehouse, the type, location, and
effective roles, with **Launch** (when allowed) and **Edit Config**. Edit exposes
the **Access Roles** picker and a **Status** select (Active / Inactive), Cancel
and Save.

**States:** loading is a blank layout until JSON returns; failures render inline
error text; there are no partial-empty states beyond "No … found".

---

## 4. Control inventory

30 interactive controls across the five screens.

| ID | Screen | Control | What it does today | Status |
|---|---|---|---|---|
| OPS-01 | Operations list | Search field | Reloads the list filtered by the typed text | ✅ |
| OPS-02 | Operations list | Type filter | Reloads the list filtered by operation type | ✅ |
| OPS-03 | Operations list | Status filter | Reloads the list filtered by active or inactive | ✅ |
| OPS-04 | Operations list | Location filter | Reloads the list filtered by one branch or warehouse | ✅ |
| OPS-05 | Operations list | Search button | Reloads the filtered page | ✅ |
| OPS-06 | Operations list | Operation name link | Opens the location appointment | ✅ |
| OPS-07 | Operations list | Launch icon | Launches when active and allowed; otherwise disabled with a reason | ✅ |
| OPS-08 | Operations list | Edit Config icon | Opens the location appointment editor | ✅ |
| OPS-09 | Configs list | Search field | Submits `q` | ✅ |
| OPS-10 | Configs list | Type filter | Submits `operation_type` | ✅ |
| OPS-11 | Configs list | Status filter | Submits `workflow_status` | ✅ |
| OPS-12 | Configs list | Search button | Reloads the filtered page | ✅ |
| OPS-13 | Configs list | Config name link | Opens the config detail | ✅ |
| OPS-14 | Configs list | Edit icon | Opens the config editor | ✅ |
| OPS-15 | Config detail | Back to Operation Configs | Returns to the list | ✅ |
| OPS-16 | Config detail | Edit Config | Opens the editor | ✅ |
| OPS-17 | Config edit | Roles picker | Opens the checkbox menu | ✅ |
| OPS-18 | Config edit | Role checkboxes | Select company-wide roles | ✅ |
| OPS-19 | Config edit | Remove role chip | Unchecks that role | ✅ |
| OPS-20 | Config edit | Cancel | Returns to the detail | ✅ |
| OPS-21 | Config edit | Save | PATCHes roles; resets every location's copy | ✅ |
| OPS-22 | Appointment detail | Back to Operations | Returns to the list | ✅ |
| OPS-23 | Appointment detail | Launch | Opens the console when allowed | ✅ |
| OPS-24 | Appointment detail | Edit Config | Opens the location editor | ✅ |
| OPS-25 | Appointment edit | Roles picker | Opens the checkbox menu | ✅ |
| OPS-26 | Appointment edit | Role checkboxes | Select roles for this location | ✅ |
| OPS-27 | Appointment edit | Remove role chip | Unchecks that role | ✅ |
| OPS-28 | Appointment edit | Status select | Active or Inactive | ✅ |
| OPS-29 | Appointment edit | Cancel | Returns to the detail | ✅ |
| OPS-30 | Appointment edit | Save | PATCHes roles and status | ✅ |

**Count by status:** ✅ 30 · everything works. The problems on this area are
omissions and one layout defect, not dead controls.

---

## 5. Numbers and claims on screen

| Claim | Meaning | Source | Verdict |
|---|---|---|---|
| Locations (count) | How many branch + warehouse appointments exist | Real counts from both appointment tables | ✅ |
| Access Roles chips | Who may use the operation | Effective roles: operation roles intersected with location roles | ✅ |
| "All roles" | Everyone with Operations read may use it | Empty role list | ✅ |
| Status badge | Active or inactive at this location | Appointment workflow status | ✅ |
| Type | POS / Booking / Inventory / Reception / Store Manager | Operation type | ✅ |
| "Saving config here resets every branch and warehouse config." | A warning with consequences | True: the save copies metadata to all appointments | ✅ honest warning |
| Launch disabled reason | Why launching is blocked | Inactive, or no access | ✅ |

**No fabricated numbers were found in this area.** The one visible defect is in
the operations table:

- The table declares **seven** columns (Operation, Type, Location, Resolution,
  Status, Access Roles, Actions) but each row renders **six** cells. From column
  four onward the data sits under the wrong heading: the status badge appears
  under "Resolution", the role chips under "Status", and the action icons under
  "Access Roles". The "Actions" heading has no cells beneath it.

---

## 6. Gaps by user job

### G1 — "The table headings do not match the data."
A seven-column header with six cells per row. It is the first screen an
administrator sees after onboarding.

- Smallest real version: remove the "Resolution" heading (S).
- Better: add the missing resolution column with a real value (S).

### G2 — "I want to change the operation's settings."
The page calls itself "Operation Configs" and warns about resetting locations,
but the only editable field is Access Roles. There is no description, no
per-operation option, and no way to see the metadata the system actually stores.

- Smallest real version: rename to "Access roles" (S).
- Better: expose the settings that operations actually read, as typed fields (M).

### G3 — "Turn off POS for the whole company."
Deactivation is per location only. With twenty branches, that is twenty saves.

- Smallest real version: a company-wide inactive switch on the config (M).
- Better: bulk activate/deactivate by operation type (M).

### G4 — "Add Housekeeping as an operation."
The catalog is fixed at five types and there is no create action. The code even
ships two stub controllers (`housekeeping`, `kitchen`) for types that are not in
the catalog, so they can never be reached.

- Smallest real version: delete the two stub files and state that the catalog is
  fixed (S).
- Full version: a supported way to introduce a new operation type (L, documented
  in `docs/OPERATION_PAGES.md`).

### G5 — "Who changed access, and when?"
There is no audit trail for operation config or appointment changes, although the
platform keeps logs for attendance, event, and table configs.

- Smallest real version: record who changed roles and when (M).

### G6 — "I renamed a role and lost access."
Roles are stored **by name** in the operation metadata and matched by name at
request time. Renaming a role silently removes access for everyone who had it.

- Smallest real version: resolve roles by id and display the current name (M).
- Alternative: block renaming a role that is referenced, with a clear message (S).

### G7 — "What will this role actually see?"
There is no preview. An administrator must save, switch account, and try.

- Smallest real version: a read-only summary of the launched console name and the
  included roles (S).
- Better: a "view as role" preview (M).

### G8 — "Why is this operation missing at this branch?"
If an operation was added to the catalog after a company was created, no
appointment exists for existing branches. The platform has a documented backfill
procedure but no UI.

- Smallest real version: show a warning and a "repair" action for missing
  appointments (M).

### G9 — "Too many locations to scan."
No pagination or sorting controls; the list is one flat table sorted by operation
name then location.

- Smallest real version: sortable headers (S).
- Better: filter by "only show inactive" and paginate (M).

---

## 7. Decisions for the BA

**OPS-D1 — Fix the table by removing or adding a column?**
- A. Remove the "Resolution" heading. Effort S.
- B. Add a real Resolution column (for example, effective config source:
  operation vs location). Effort S–M.
- *Recommendation:* B. The concept exists (config resolution) and admins will ask
  why the page says "Resolution" otherwise.

**OPS-D2 — Does configuration become real?**
- A. Rename the area to Access Roles. Effort S.
- B. Expose each operation's real settings as typed fields. Effort L, one field at
  a time.
- *Recommendation:* A now, B per operation as each console defines what it reads.

**OPS-D3 — Company-wide activation?**
- A. Keep per-location only. Effort S.
- B. Add a company-wide switch with a bulk apply. Effort M.
- *Recommendation:* B once a company has more than a handful of locations.

**OPS-D4 — Housekeeping and Kitchen stubs?**
- A. Delete both stub controllers. Effort S.
- B. Register them as real operation types. Effort L.
- *Recommendation:* A. Shipping unreachable code implies support that does not
  exist.

**OPS-D5 — Roles by name or by identity?**
- A. Keep names. Effort S. Risk: a rename silently revokes access.
- B. Store role ids and resolve names at render time. Effort M.
- *Recommendation:* B before any customer renames a role.

**OPS-D6 — Access audit trail?**
- A. No trail. Effort S.
- B. Log role and status changes with actor and time. Effort M.
- *Recommendation:* B for any customer with staff turnover or compliance needs.

**OPS-D7 — Bulk actions?**
- A. One location at a time. Effort S.
- B. Multi-select activate/deactivate. Effort M.
- *Recommendation:* B with OPS-D3; they are the same job.

**OPS-D8 — Missing appointments after a catalog change?**
- A. Leave the documented manual procedure. Effort S.
- B. Detect and offer a repair. Effort M.
- *Recommendation:* B — silent missing consoles are the worst kind of support
  ticket.

---

## 8. Safe demo path

1. Open **Operations** and show the table with branches and warehouses.
2. Filter by **POS** and by **Inactive**.
3. Launch Store Manager from a row.
4. Return, open a location, show the effective roles, then **Edit Config**.
5. Change the status to Inactive, save, return to the list, and show the launch
   icon disabled with its reason.
6. Open **Operation Configs**, open POS, show the roles, and open the editor.

**Do not demo:**

- The operations table as-is without explaining the column offset — it looks
  broken.
- "Resolution" as a meaningful column.
- Adding an operation type, or Housekeeping/Kitchen — they do not exist.
- A role rename (it would silently revoke access).
- Any claim of an audit trail.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations(.json)` — filters `q`,
  `operation_type`, `workflow_status`, `location`.
- `GET /companies/:company_id/operations/:id/launch`
- `GET /companies/:company_id/operation_configs(.json)` and `/:id`,
  `/:id/edit`, `PATCH /:id`
- `GET /companies/:company_id/branch_operation_appointments/:id`, `/edit`,
  `PATCH`
- `GET /companies/:company_id/operation_warehouse_appointments/:id`, `/edit`,
  `PATCH`

**Backend:** `Companies::OperationsController`, `Companies::OperationConfigsController`,
`Companies::BranchOperationAppointmentsController`,
`Companies::OperationWarehouseAppointmentsController`; `OperationSerializer`,
`OperationLaunchService`.

**Frontend:** `companies/operations/index_controller.js`,
`companies/operation_configs/{index,show,edit}_controller.js`,
`companies/operation_appointments/{show,edit}_controller.js`, with thin
subclasses for branch and warehouse.

**Caching:** the operations index payload is cached per company in
`Rails.sync_cache` for `OPERATIONS_CACHE_EXPIRY`; `OperationPageCacheConcern`
clears it on writes. The per-employee `accessible` flag is computed after the
cache read, not cached.

**Known code-level issues behind §5 and §6:**

- `rowHTML` in `operations/index_controller.js` renders six `<td>` cells against
  seven `<th>` headings.
- `Operation#effective_roles` and `accessible_by?` compare
  `employee.roles.where(name: allowed)` — roles are names in metadata.
- `Companies::OperationConfigsController#update` writes metadata (roles) and
  copies it to every appointment via the model callback.
- `OperationLaunchService::ROUTES` maps the five catalog types and raises
  `KeyError` for anything else.
- `app/javascript/controllers/companies/operations/housekeeping/show_controller.js`
  and `kitchen/show_controller.js` are three-line placeholders for types absent
  from `OPERATION_TYPES`, with no routes or backend controllers.

**Source tables:** `operations`, `branch_operation_appointments`,
`operation_warehouse_appointments`, `branches`, `warehouses`, `roles`.

**Proof:** `spec/features/companies/operations/index_spec.rb`,
`spec/features/companies/operation_configs/index_spec.rb`,
`spec/requests/companies/operations/*.rb`,
`spec/services/seed/operation_service_spec.rb`.

**Not covered by tests:** the column mismatch, role renames, company-wide
deactivation, and missing-appointment repair.
