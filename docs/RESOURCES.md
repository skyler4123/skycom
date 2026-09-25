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
| 24 | `order_groups` | Sales | Order grouping (batches/carts) |
| 25 | `orders` | Sales | Customer orders |
| 26 | `order_appointments` | Sales | Order line items |
| 27 | `cart_groups` | Sales | Cart grouping |
| 28 | `carts` | Sales | Shopping cart sessions |
| 29 | `invoices` | Billing | Customer invoices |
| 30 | `payments` | Billing | Payment transactions |
| 31 | `payment_methods` | Billing | Accepted payment types |
| 32 | `facility_groups` | Facilities | Facility grouping |
| 33 | `facilities` | Facilities | Treatment rooms, machines, resources |
| 34 | `project_groups` | Projects | Project grouping |
| 35 | `projects` | Projects | Work projects |
| 36 | `task_groups` | Tasks | Task grouping |
| 37 | `tasks` | Tasks | Work tasks / appointments |
| 38 | `notification_groups` | Notifications | Notification grouping |
| 39 | `notifications` | Notifications | System/user notifications |
| 40 | `exam_groups` | Education | Exam/test grouping |
| 41 | `exams` | Education | Exam/test instances |
| 42 | `questions` | Education | Exam questions |
| 43 | `answers` | Education | Exam answers |
| 44 | `event_groups` | Events | Event grouping |
| 45 | `events` | Events | Calendar events / promotions |
| 46 | `setting_groups` | Config | Configuration grouping |
| 47 | `settings` | Config | Application/company settings |
| 48 | `document_groups` | Content | Document grouping |
| 49 | `documents` | Content | Business documents |
| 50 | `article_groups` | Content | Article grouping |
| 51 | `articles` | Content | Knowledge base / articles |
| 52 | `subscription_plans` | Subscriptions | Service subscription plan definitions |
| 53 | `subscription_groups` | Subscriptions | Subscription group instances |
| 54 | `shifts` | HR | Work shift definitions |
| 55 | `attendance_logs` | HR | Staff clock-in/out events |
| 56 | `attendance_days` | HR | Daily attendance summaries |
| 57 | `attendance_months` | HR | Monthly attendance rollups |
| 58 | `memberships` | CRM | Customer loyalty/program memberships |
| 59 | `reservations` | Bookings | Customer service bookings |
| 60 | `suppliers` | Inventory | Supplier records (procurement-ready master data) |
| 61 | `discount_groups` | Sales | Discount campaign groups (type/value, budget, validity, status) |
| 62 | `discounts` | Sales | Single-use discount codes (unique per company, consumption state, SoT bindings) |

**Total: 62 tables**

---

## 4. Appointment Resources

Atomic pairwise join tables: one table per resource pair, named alphabetically (`A_B_appointments`, e.g., `article_employee_appointments`, `employee_role_appointments`). Each row links exactly two records via concrete FKs plus `company_id` — there is no polymorphic `appoint_to` / `appoint_from` / `appoint_for` / `appoint_by` pattern. All table names end with `_appointments`. Domain extras: `quantity` / `unit_price` / `total_price` (order, purchase line items), `duration` / `start_at` (service bookings).

| # | Group | Tables | Count |
|---|-------|--------|-------|
| 1 | Address links | `address_branch`, `address_company`, `address_customer`, `address_customer_group`, `address_department`, `address_employee`, `address_employee_group`, `address_user` | 8 |
| 2 | Tag links | `answer_tag`, `article_tag`, `article_group_tag`, `branch_tag`, `brand_tag`, `company_tag`, `customer_tag`, `customer_group_tag`, `department_tag`, `document_tag`, `document_group_tag`, `employee_tag`, `employee_group_tag`, `event_tag`, `event_group_tag`, `exam_tag`, `exam_group_tag`, `facility_tag`, `facility_group_tag`, `invoice_tag`, `notification_tag`, `notification_group_tag`, `order_tag`, `order_group_tag`, `product_tag`, `product_group_tag`, `project_tag`, `project_group_tag`, `purchase_tag`, `purchase_item_tag`, `question_tag`, `role_tag`, `service_tag`, `service_group_tag`, `setting_tag`, `setting_group_tag`, `statistic_tag`, `stock_tag`, `stock_export_tag`, `stock_import_tag`, `stock_transfer_tag`, `subscription_group_tag`, `supplier_tag`, `tag_task`, `tag_task_group`, `tag_transaction`, `tag_warehouse` | 47 |
| 3 | Generic pairwise links | `article_employee`, `article_group_employee`, `cart_employee`, `customer_customer_group`, `customer_employee`, `customer_group_service`, `customer_service` (booking: `duration`, `start_at`), `department_employee`, `document_employee`, `document_group_employee`, `employee_employee` (self-link via `related_employee_id`), `employee_employee_group`, `employee_event`, `employee_event_group`, `employee_exam`, `employee_facility`, `facility_facility_group`, `employee_notification`, `employee_notification_group`, `employee_product`, `product_product_group`, `employee_project`, `employee_project_group`, `service_service_group`, `employee_service` (booking: `duration`, `start_at`), `employee_setting`, `employee_setting_group`, `employee_task`, `employee_task_group` | 29 |
| 4 | Order line items | `order_product`, `order_product_group`, `order_service`, `order_service_group`, `order_subscription_plan` (each with `quantity` / `unit_price` / `total_price` snapshots) | 5 |
| 5 | Payment method links | `branch_payment_method`, `company_payment_method` | 2 |
| 6 | Policy / role assignments | `policy_role`, `customer_role`, `customer_group_role`, `department_role`, `employee_group_role`, `employee_role` | 6 |
| 7 | Membership / reservation | `customer_membership`, `customer_reservation` | 2 |
| 8 | Purchase line items | `purchase_purchase_item` (`quantity` / `unit_price` / `total_price`) | 1 |
| 9 | Subscription links | `branch_subscription_plan`, `subscription_group_subscription_plan` | 2 |
| 10 | Order-group link | `employee_order_group` (`quantity` / `unit_price` / `total_price`) | 1 |

**Total: 103 tables**

---

## Summary

| Category | Count |
|----------|-------|
| Gem Resources | 4 |
| System Resources | 11 |
| Managed Resources | 62 |
| Appointment Resources | 103 |
| **Grand Total** | **180** |

---

**Note:** Former polymorphic tables (`article_appointments`, `role_appointments`, `order_appointments`, etc. using `appoint_to` / `appoint_from`) are dropped and replaced by the atomic pairs above. The managed-resources row for `order_appointments` is kept for history pending the sales-domain update.
