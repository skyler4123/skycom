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
| 9 | `system_subscription_plans` | Platform-wide subscription plan definitions |
| 10 | `system_subscription_groups` | Subscription group (company grouping) |
| 11 | `system_subscriptions` | Company subscription instances |

**Total: 11 tables**

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
| 29 | `purchases` | Procurement | Purchase orders to suppliers |
| 30 | `purchase_items` | Procurement | Purchase order line items |
| 31 | `invoices` | Billing | Customer invoices |
| 32 | `payments` | Billing | Payment transactions |
| 33 | `payment_methods` | Billing | Accepted payment types |
| 34 | `facility_groups` | Facilities | Facility grouping |
| 35 | `facilities` | Facilities | Treatment rooms, machines, resources |
| 36 | `project_groups` | Projects | Project grouping |
| 37 | `projects` | Projects | Work projects |
| 38 | `task_groups` | Tasks | Task grouping |
| 39 | `tasks` | Tasks | Work tasks / appointments |
| 40 | `notification_groups` | Notifications | Notification grouping |
| 41 | `notifications` | Notifications | System/user notifications |
| 42 | `exam_groups` | Education | Exam/test grouping |
| 43 | `exams` | Education | Exam/test instances |
| 44 | `questions` | Education | Exam questions |
| 45 | `answers` | Education | Exam answers |
| 46 | `event_groups` | Events | Event grouping |
| 47 | `events` | Events | Calendar events / promotions |
| 48 | `setting_groups` | Config | Configuration grouping |
| 49 | `settings` | Config | Application/company settings |
| 50 | `document_groups` | Content | Document grouping |
| 51 | `documents` | Content | Business documents |
| 52 | `article_groups` | Content | Article grouping |
| 53 | `articles` | Content | Knowledge base / articles |
| 54 | `subscription_plans` | Subscriptions | Service subscription plan definitions |
| 55 | `subscription_groups` | Subscriptions | Subscription group instances |
| 56 | `shifts` | HR | Work shift definitions |
| 57 | `attendance_logs` | HR | Staff clock-in/out events |
| 58 | `attendance_days` | HR | Daily attendance summaries |
| 59 | `attendance_months` | HR | Monthly attendance rollups |
| 60 | `memberships` | CRM | Customer loyalty/program memberships |
| 61 | `reservations` | Bookings | Customer service bookings |

**Total: 61 tables**

---

## 4. Appointment Resources

Polymorphic join tables using the `appoint_to` / `appoint_from` / `appoint_for` / `appoint_by` pattern. All table names end with `_appointments`. These create many-to-many links between any two resource types.

| # | Table | Links To | Description |
|---|-------|----------|-------------|
| 1 | `address_appointments` | Address | Link any resource to an address |
| 2 | `period_appointments` | Period | Link any resource to a time range |
| 3 | `price_appointments` | Price | Link any resource to a price |
| 4 | `tag_appointments` | Tag | Link any resource to a tag |
| 5 | `policy_appointments` | Policy | Assign policy to role (many-to-many) |
| 6 | `role_appointments` | Role | Assign role to employee |
| 7 | `department_appointments` | Department | Link employee/entity to a department |
| 8 | `employee_appointments` | Employee | Link employee to any resource |
| 9 | `employee_group_appointments` | EmployeeGroup | Link employee group to any resource |
| 10 | `customer_appointments` | Customer | Link customer to any resource |
| 11 | `customer_group_appointments` | CustomerGroup | Link customer group to any resource |
| 12 | `product_appointments` | Product | Link product to any resource |
| 13 | `product_group_appointments` | ProductGroup | Link product group to any resource |
| 14 | `service_appointments` | Service | Link service to any resource |
| 15 | `service_group_appointments` | ServiceGroup | Link service group to any resource |
| 16 | `order_appointments` | Order | Link order to items (line items with qty/price) |
| 17 | `order_group_appointments` | OrderGroup | Link order group to any resource |
| 18 | `cart_appointments` | Cart | Link cart to products/variants |
| 19 | `payment_method_appointments` | PaymentMethod | Link payment method to branch/company |
| 20 | `facility_appointments` | Facility | Link facility to any resource |
| 21 | `facility_group_appointments` | FacilityGroup | Link facility group to any resource |
| 22 | `project_appointments` | Project | Link project to any resource |
| 23 | `project_group_appointments` | ProjectGroup | Link project group to any resource |
| 24 | `task_appointments` | Task | Link task to any resource |
| 25 | `task_group_appointments` | TaskGroup | Link task group to any resource |
| 26 | `notification_appointments` | Notification | Link notification to any resource |
| 27 | `notification_group_appointments` | NotificationGroup | Link notification group to any resource |
| 28 | `exam_appointments` | Exam | Link exam to any resource |
| 29 | `event_appointments` | Event | Link event to any resource |
| 30 | `event_group_appointments` | EventGroup | Link event group to any resource |
| 31 | `setting_appointments` | Setting | Link setting to any resource |
| 32 | `setting_group_appointments` | SettingGroup | Link setting group to any resource |
| 33 | `document_appointments` | Document | Link document to any resource |
| 34 | `document_group_appointments` | DocumentGroup | Link document group to any resource |
| 35 | `article_appointments` | Article | Link article to any resource |
| 36 | `article_group_appointments` | ArticleGroup | Link article group to any resource |
| 37 | `membership_appointments` | Membership | Link membership to any resource |
| 38 | `reservation_appointments` | Reservation | Link reservation to any resource |
| 39 | `subscription_plan_appointments` | SubscriptionPlan | Link subscription plan to groups/resources |

**Total: 39 tables**

---

## Summary

| Category | Count |
|----------|-------|
| Gem Resources | 4 |
| System Resources | 11 |
| Managed Resources | 61 |
| Appointment Resources | 39 |
| **Grand Total** | **115** |

---

**Note:** The managed resources count includes `order_appointments` (line items) which, despite the name pattern, functions as a line-item table with quantity/price columns rather than a pure polymorphic join. All appointment-*pattern* tables are consolidated under Appointment Resources.
