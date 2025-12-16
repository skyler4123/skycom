# Skycom Retail: Post-Authentication Implementation Roadmap

Now that the **Sign In/Up/Out** features are complete, the application knows *who* the user is. The next phase is to establish **Context**: defining *what* organization they belong to, *where* they are working (Branch), and *what* they are allowed to do.

---

## Phase 1: The Multi-Tenant Foundation
**Goal:** Create the "container" for all business data.

### 1. Business Hierarchy Setup
* **Organization (Company Group):** The top-level tenant (e.g., "Skycom Retail Group"). This entity owns the Catalog, Customers, and Roles.
* **Branch (Company/Location):** The physical storefront (e.g., "Main St. Boutique"). Orders and Inventory stock levels are tracked here.
* **Onboarding Flow:** Create a "Setup Wizard" for new users to:
    1. Create their Organization.
    2. Create their first Branch.
    3. Automatically become the "Owner" of that Organization.

### 2. Permissions & Access Control (IAM)
* **Roles:** Create a `Role` model (e.g., `Owner`, `Manager`, `Cashier`).
* **Policies:** Implement logic to ensure data isolation (e.g., a Cashier at Branch A cannot see sales for Branch B).
* **Global Scoping:** Implement a `current_organization` helper in your backend controller to ensure all database queries are scoped to the logged-in user's business.

---

## Phase 2: Configuration & Master Data
**Goal:** Define the rules and the items being sold.

### 1. Global Settings
* **Payment Methods:** A configuration page for the Owner to enable/disable payment types (Cash, Credit Card, QR Code, etc.).
* **Tagging System:** A CRUD interface for tags used to categorize Products ("New Arrival") or Customers ("VIP").

### 2. Unified Catalog
* **Products:** Items requiring inventory tracking (SKUs, cost, sale price).
* **Services:** Non-inventory items (e.g., "Installation Fee", "Consultation", "Shipping").
* **Branch Inventory:** A system to map Products to specific Branches with unique stock quantities.

---

## Phase 3: People & CRM
**Goal:** Add the actors who interact with the system.

* **Employee Management:** An interface for the Owner to invite users to the Organization and assign them to specific Branches with a Role.
* **Customer CRM:** A shared database for the Organization. Customers can be registered at one branch and recognized at another.

---

## Technical Implementation Checklist

| Priority | Task | Description |
| :--- | :--- | :--- |
| **P0** | **Tenant Migrations** | Create `organizations` and `branches` tables. |
| **P0** | **Relationship Linking** | Add `organization_id` to Users, Products, and Customers. |
| **P1** | **Context Helper** | Logic to set `@current_branch` and `@current_organization` on login. |
| **P1** | **Product/Service CRUD** | Forms to build the selling catalog. |
| **P2** | **Role-Based Access** | Restrict UI elements based on the User's role. |

---

## Recommended Next Step
1.  **Generate Migrations:** Create the `Organization` and `Branch` models.
2.  **Update Application Controller:** Add a method to fetch the "Active Organization" for the logged-in user.
