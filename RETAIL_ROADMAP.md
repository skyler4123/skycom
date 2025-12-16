# Skycom Retail Vertical: Multi-Tenant Development Roadmap

This document outlines the step-by-step development of the Skycom Retail vertical, transitioning from a core sales tool to a high-scale, multi-tenant enterprise solution.

---

## Phase 1: Multi-Tenant & Identity Foundation
**Goal:** Establish the structural hierarchy and the onboarding experience for Business Owners (Super Admins).

1.  **Identity & Access Management (IAM):**
    * **User Authentication:** Implement `has_secure_password` for secure login.
    * **Organization (Company Group):** The top-level tenant. All data (Products, Customers, Roles) belongs to this entity.
    * **Branch (Company):** A physical or logical location under an Organization. Orders and Inventory are branch-specific.
2.  **Permissions & Governance:**
    * **Role & Policy:** Define granular permissions at the Organization level (e.g., "Branch Manager" can view reports, "Cashier" can only create orders).
    * **Membership:** Link `Users` to an `Organization` with a specific assigned `Role`.
3.  **Organization Configuration:**
    * **Payment Methods:** CRUD for allowed payment types (Cash, Credit, Split, etc.) per Organization.
    * **Global Tags:** A centralized tagging system to categorize Products, Services, and Customers across all branches.

---

## Phase 2: Catalog & CRM (Data Input)
**Goal:** Populate the Organization’s master data to be utilized across all operating branches.

1.  **Unified Catalog:**
    * **Products:** Physical goods requiring inventory tracking, SKU management, and cost/price fields.
    * **Services:** Non-inventory items (e.g., "Consultation," "Repairs," "Installation Fees").
2.  **Centralized CRM:**
    * **Customer Profiles:** A shared database across the Organization so a client can visit any Branch and maintain their history and loyalty status.
    * **Customer Tagging:** Segmenting customers (e.g., "VIP," "Wholesale") using the global tag system.
3.  **Staffing:**
    * Interface to add **Employees** to the Organization and assign them to specific primary **Branches**.

---

## Phase 3: Sales & Inventory Operations
**Goal:** High-speed order creation and real-time inventory tracking at the branch level.

1.  **Branch-Level Inventory:**
    * While Product definitions are global, stock levels are tracked individually per `Branch`.
    * Implement "Stock Adjustments" for manual overrides and stocktakes.
2.  **The Order Engine:**
    * **Order Model:** Must capture `Organization_id`, `Branch_id`, `User_id` (Employee), and `Customer_id`.
    * **Order Items:** Use a polymorphic association to handle both `Products` (which deduct inventory) and `Services` in one transaction.
3.  **POS Interface (`Retail::Pos` namespace):**
    * **Dynamic Checkout:** Single-screen interface powered by **Hotwire (Turbo/Stimulus)** for instant updates without page reloads.
    * **Payment Recording:** Finalize orders by selecting from the Organization's pre-defined `PaymentMethods`.

---

## Phase 4: Management & Analytics
**Goal:** Turn transactional data into business intelligence for the Organization owner.

1.  **Management Dashboard:**
    * Aggregate sales data across the entire Organization or filter by specific Branches.
    * Display metrics using `ApexCharts` (Revenue, Order volume, Top-selling products).
2.  **Reporting & Insights:**
    * **Sales Reports:** Filter by date range, brand, or employee performance.
    * **Inventory Reports:** Stock value and "Low Stock" alerts per branch.
3.  **Retail Appointments:**
    * Implement retail-specific appointments (e.g., "Personal Shopping") linked to an `Employee` and a `Branch`.

---

## Data Hierarchy Summary

| Entity | Level | Responsibility |
| :--- | :--- | :--- |
| **Organization** | Primary Tenant | Roles, Policies, Products, Services, Payment Methods, Customers. |
| **Branch** | Operational Unit | Inventory Stock Levels, Orders, Local Staff Assignments. |
| **User** | Actor | Credentials, Profile, and assigned Role/Branch access. |

---

> **The User Flow:**
> 1. Sign up $\rightarrow$ 2. Create Organization $\rightarrow$ 3. Add Branches $\rightarrow$ 4. Define Roles/Payment Methods $\rightarrow$ 5. Add Catalog (Products/Services) $\rightarrow$ 6. Add Employees $\rightarrow$ 7. Open POS & Create Orders.