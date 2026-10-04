# Skycom Database Resource Catalog

> Auto-generated from `db/schema.rb` — all tables declared in migration files, categorized by role.

---

## 1. Gem Resources

Tables created by Rails engines or third-party gems. Not company-scoped; maintained by their respective frameworks.

| # | Table | Origin | Purpose |
|---|-------|--------|---------|
| 1 | `active_storage_blobs` | Active Storage | File metadata storage |
| 2 | `active_storage_attachments` | Active Storage | Polymorphic join: files ↔ records |
| 3 | `active_storage_variant_records` | Active Storage | Cached image variant metadata |
| 4 | `versions` | PaperTrail | Audit trail / object versioning |

**Total: 4 tables**

---

## 2. System Resources

Platform-level tables that span across all companies. Identity, auth, shared references, and billing.

| # | Table | Purpose |
|---|-------|---------|
| 1 | `systems` | Platform system singleton record |
| 2 | `users` | User accounts (cross-company) |
| 3 | `sessions` | User session tracking |
| 4 | `sign_in_tokens` | Magic-link / token-based authentication |
| 5 | `addresses` | Shared immutable address reference |
| 6 | `periods` | Shared immutable time-range reference |
| 7 | `prices` | Shared immutable monetary-value reference |
| 8 | `statistics` | Polymorphic analytics / metric snapshots |

**Total: 8 tables**

---

## 3. Managed Resources

Company-scoped business entities. Each table belongs to a `company_id` and represents a core domain object.

| # | Table | Domain | Description |
|---|-------|--------|-------------|
| 1 | `companies` | Core | Tenant company records |
| 2 | `categories` | Taxonomy | Dynamic schema grouping (products, employees, etc.) |
| 3 | `property_mappings` | Taxonomy | Dynamic property label definitions per category |
| 4 | `table_configs` | Taxonomy | Column visibility and order per category |
| 5 | `branches` | Structure | Physical or virtual branch locations |
| 6 | `departments` | Structure | Organizational departments |
| 7 | `tags` | ABAC | Key-value tags for ABAC policy evaluation |
| 8 | `roles` | ABAC | Employee roles with associated policies |
| 9 | `policies` | ABAC | Permission policies with tag conditions |
| 10 | `employee_groups` | HR | Employee grouping |
| 11 | `employees` | HR | Staff members |
| 12 | `customer_groups` | CRM | Customer segmentation groups |
| 13 | `customers` | CRM | Customer/patient records |
| 14 | `brands` | Catalog | Product brand/manufacturer records |
| 15 | `product_groups` | Catalog | Product collection grouping |
| 16 | `products` | Catalog | Retail goods / physical items |
| 17 | `services` | Catalog | Clinic services / intangible offerings |
| 18 | `service_groups` | Catalog | Service collection grouping |
| 19 | `warehouses` | Inventory | Warehouse locations |
| 20 | `stocks` | Inventory | Stock-keeping records per product/warehouse |
| 21 | `stock_transfers` | Inventory | Inter-warehouse stock movement |
| 22 | `stock_imports` | Inventory | Inbound stock (supplier receipts) |
| 23 | `stock_exports` | Inventory | Outbound stock (write-offs, damages) |
| 24 | `stock_adjustments` | Inventory | Stock-take corrections (direction + reason) |
| 25 | `order_groups` | Sales | Order grouping (batches/carts) |
| 26 | `orders` | Sales | Customer orders |
| 27 | `order_appointments` | Sales | Order line items |
| 28 | `cart_groups` | Sales | Cart grouping |
| 29 | `carts` | Sales | Shopping cart sessions |
| 30 | `invoices` | Billing | Customer invoices |
| 31 | `payments` | Billing | Payment transactions |
| 32 | `payment_methods` | Billing | Accepted payment types |
| 33 | `facility_groups` | Facilities | Facility grouping |
| 34 | `facilities` | Facilities | Treatment rooms, machines, resources |
| 35 | `project_groups` | Projects | Project grouping |
| 36 | `projects` | Projects | Work projects |
| 37 | `task_groups` | Tasks | Task grouping |
| 38 | `tasks` | Tasks | Work tasks / appointments |
| 39 | `notification_groups` | Notifications | Notification grouping |
| 40 | `notifications` | Notifications | System/user notifications |
| 41 | `exam_groups` | Education | Exam/test grouping |
| 42 | `exams` | Education | Exam/test instances |
| 43 | `questions` | Education | Exam questions |
| 44 | `answers` | Education | Exam answers |
| 45 | `event_groups` | Events | Event grouping |
| 46 | `events` | Events | Calendar events / promotions |
| 47 | `setting_groups` | Config | Configuration grouping |
| 48 | `settings` | Config | Application/company settings |
| 49 | `document_groups` | Content | Document grouping |
| 50 | `documents` | Content | Business documents |
| 51 | `article_groups` | Content | Article grouping |
| 52 | `articles` | Content | Knowledge base / articles |
| 53 | `subscription_plans` | Subscriptions | Service subscription plan definitions |
| 54 | `subscription_groups` | Subscriptions | Subscription group instances |
| 55 | `shifts` | HR | Work shift definitions |
| 56 | `attendance_logs` | HR | Staff clock-in/out events |
| 57 | `attendance_days` | HR | Daily attendance summaries |
| 58 | `attendance_months` | HR | Monthly attendance rollups |
| 59 | `memberships` | CRM | Customer loyalty/program memberships |
| 60 | `reservations` | Bookings | Customer service bookings |
| 61 | `suppliers` | Inventory | Supplier records (procurement-ready master data) |
| 62 | `discount_groups` | Sales | Discount campaign groups (type/value, budget, validity, status) |
| 63 | `discounts` | Sales | Single-use discount codes (unique per company, consumption state, SoT bindings) |
| 64 | `stock_pendings` | Inventory | Owner-less pending-hold records (one hold ledger row on reserve, one release row on consume/release) |
| 65 | `event_configs` | Events | Per-category event rules (stock holds, order bridge, overlap warnings) |

**Total: 65 tables**

---

## 4. Appointment Resources

Atomic pairwise join tables: one table per resource pair, named alphabetically (`A_B_appointments`, e.g., `article_employee_appointments`, `employee_role_appointments`). Each row links exactly two records via concrete FKs plus `company_id` — there is no polymorphic `appoint_to` / `appoint_from` / `appoint_for` / `appoint_by` pattern. All table names end with `_appointments`. Domain extras: `quantity` / `unit_price` / `total_price` (order, purchase line items), `duration` / `start_at` (service bookings).

| # | Group | Tables | Count |
|---|-------|--------|-------|
| 1 | Address links | `address_branch`, `address_company`, `address_customer`, `address_customer_group`, `address_department`, `address_employee`, `address_employee_group`, `address_user` | 8 |
| 2 | Tag links | `answer_tag`, `article_tag`, `article_group_tag`, `branch_tag`, `brand_tag`, `company_tag`, `customer_tag`, `customer_group_tag`, `department_tag`, `document_tag`, `document_group_tag`, `employee_tag`, `employee_group_tag`, `event_tag`, `event_group_tag`, `exam_tag`, `exam_group_tag`, `facility_tag`, `facility_group_tag`, `invoice_tag`, `notification_tag`, `notification_group_tag`, `order_tag`, `order_group_tag`, `product_tag`, `product_group_tag`, `project_tag`, `project_group_tag`, `purchase_tag`, `purchase_item_tag`, `question_tag`, `role_tag`, `service_tag`, `service_group_tag`, `setting_tag`, `setting_group_tag`, `statistic_tag`, `stock_tag`, `stock_export_tag`, `stock_import_tag`, `stock_transfer_tag`, `subscription_group_tag`, `supplier_tag`, `tag_task`, `tag_task_group`, `tag_transaction`, `tag_warehouse` | 47 |
| 3 | Generic pairwise links | `article_employee`, `article_group_employee`, `branch_event`, `cart_employee`, `customer_customer_group`, `customer_employee`, `customer_event`, `customer_group_service`, `customer_service` (booking: `duration`, `start_at`), `department_employee`, `document_employee`, `document_group_employee`, `employee_employee` (self-link via `related_employee_id`), `employee_employee_group`, `employee_event`, `employee_event_group`, `employee_exam`, `employee_facility`, `event_facility`, `event_order`, `event_service`, `event_stock` (requirement: `quantity`, no role), `facility_facility_group`, `employee_notification`, `employee_notification_group`, `employee_product`, `product_product_group`, `employee_project`, `employee_project_group`, `service_service_group`, `employee_service` (booking: `duration`, `start_at`), `employee_setting`, `employee_setting_group`, `employee_task`, `employee_task_group` | 35 |
| 4 | Order line items | `order_product`, `order_product_group`, `order_service`, `order_service_group`, `order_subscription_plan` (each with `quantity` / `unit_price` / `total_price` snapshots) | 5 |
| 5 | Payment method links | `branch_payment_method`, `company_payment_method` | 2 |
| 6 | Policy / role assignments | `policy_role`, `customer_role`, `customer_group_role`, `department_role`, `employee_group_role`, `employee_role` | 6 |
| 7 | Membership / reservation | `customer_membership`, `customer_reservation` | 2 |
| 8 | Purchase line items | `purchase_purchase_item` (`quantity` / `unit_price` / `total_price`) | 1 |
| 9 | Subscription links | `branch_subscription_plan`, `subscription_group_subscription_plan` | 2 |
| 10 | Order-group link | `employee_order_group` (`quantity` / `unit_price` / `total_price`) | 1 |
| 11 | Stock document lines | `stock_import_stock`, `stock_export_stock`, `stock_transfer_stock`, `stock_adjustment_stock` (each `stock_id` + `quantity`; document lines reference exact Stock rows) | 4 |

**Total: 113 tables**

---

## 5. Why Atomic? (Decision Record)

Before this refactor, 38 polymorphic `*_appointments` tables linked records
through `appoint_to` / `appoint_from` / `appoint_for` / `appoint_by` columns.
Every join was a polymorphic lookup, mismatched pairs were possible at the
schema level, and per-domain extras (prices, merchant identity, durations) had
nowhere typed to live. The refactor
(`59490bf7`, split into migrations `20260925000001..20260925000103`, one per atomic table)
replaced them with 103 single-purpose tables:

- **One table per resource pair, named alphabetically** (`A_B_appointments`).
  Join the two class names, sort, append `Appointment`:
  `Department + Employee → DepartmentEmployeeAppointment`.
  Two exceptions sort Tag first: `Tag` beats `Task`/`TaskGroup`/`Transaction`/
  `Warehouse` (`TagTaskAppointment`), and `Role` sorts last
  (`EmployeeRoleAppointment`).
- **Concrete FKs + `company_id` on every row.** No polymorphic columns remain.
  `company_id` is derived from either side by `SetDefaultCompanyConcern`, so
  multi-tenant scoping (ABAC, permissions cache) holds without caller effort.
- **Domain extras live on the pair that needs them** (see §4): price snapshots
  on order/purchase lines, merchant identity on payment links, `duration` /
  `start_at` on service bookings — never on a shared polymorphic row.
- **Writes go through owner-side helpers**, not raw inserts: `attach_tag`
  (`TagConcern`), `attach_address` (`AddressConcern`), `attach_role`
  (`RoleConcern`), `attach_membership` / `attach_reservation`
  (`MembershipConcern` / `ReservationConcern`). `OrderConcern` is a no-op
  marker; order lines are bulk-inserted by
  `OrderProcessingV1::CreateOrderService`.
- Every atomic model carries a why/use/work header comment; every routing
  concern documents Purpose / How It Works / Usage / Example (see
  `SetDefaultCompanyConcern` for the template).

## 6. Adding a New Pair (Recipe)

1. **Migration**: `create_table :a_b_appointments, id: :uuid` with
   `company_id` (NOT NULL), the two concrete FKs, any domain extras, and the
   standard System Fields block (`docs/ARCHITECTURE_GUIDES.md`).
2. **Model** `app/models/a_b_appointment.rb`: `include SetDefaultCompanyConcern`,
   the two `belongs_to`, plus the matching per-family header (why / how to
   use / how it works).
3. **Routing**: if the pair belongs to a routed family, register it —
   `TagConcern` resolves alphabetically with no registry;
   `AddressConcern::ADDRESS_APPOINTMENT_CLASSES` needs the new entry;
   `RoleConcern` assumes `<Holder>RoleAppointment`.
4. **Associations**: `has_many` / `has_many :through` on both sides (or extend
   the owning concern).
5. **Seed + factory + spec**: mirror an existing pair's
   `Seed::*AppointmentService`, factory, and `*_appointment_spec.rb`
   (associations + company derivation).

---

## Summary

| Category | Count |
|----------|-------|
| Gem Resources | 4 |
| System Resources | 11 |
| Managed Resources | 65 |
| Appointment Resources | 113 |
| **Grand Total** | **193** |

---

**Note:** Former polymorphic tables (`article_appointments`, `role_appointments`, `order_appointments`, etc. using `appoint_to` / `appoint_from`) are dropped and replaced by the atomic pairs above. The managed-resources row for `order_appointments` is kept for history pending the sales-domain update.
