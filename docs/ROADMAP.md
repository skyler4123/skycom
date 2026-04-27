# 🚀 Skycom Retail Build Plan
*Goal: Build the essential screens and buttons needed to ship a working Retail POS.*

---

## 🚪 Phase 1: Entry & Company Creation
*Focus: Getting users into the system and establishing their workspace.*

- [ ] **The Login System**
    - [ ] Build a **Sign-Up** page (Email/Password).
    - [ ] Build a **Login/Logout** flow.
    - [ ] Build a **Create Company** screen (Name, Phone, Currency) that appears automatically after sign-up.
- [ ] **The "Workspace" Walls**
    - [ ] Implement logic so a user **only** sees data belonging to their active company.
    - [ ] Build a **Company Switcher** in the sidebar (for users with multiple businesses).
- [ ] **Company Settings**
    - [ ] Build a page to edit Company details (Logo, Address, Contact Info) for receipts.

## 📦 Phase 2: Inventory & The Dashboard
*Focus: Adding products and creating the "Visual Hook" for the owner.*

- [ ] **Product Catalog**
    - [ ] Build an **Add Product** form (Name, Price, Cost, SKU, and "Minimum Stock Level").
    - [ ] Build a **Product List** table with search and filtering.
- [ ] **Stock Management**
    - [ ] Build a way to manually **Update Stock** (e.g., "Received 50 units").
    - [ ] Create a **Low Stock Indicator** (a red badge/status when stock < Minimum Level).
- [ ] **The "At-a-Glance" Dashboard**
    - [ ] **Stat Card 1:** Total Sales value today ($).
    - [ ] **Stat Card 2:** Total Orders count today (#).
    - [ ] **Stat Card 3:** New Customers count.
    - [ ] **Alert Block:** A list of "Low Stock Items" requiring immediate attention.
    - [ ] **Visual Chart:** A simple bar chart showing sales for the last 7 days.

## 🛒 Phase 3: The POS & Sales
*Focus: The "Money Maker" — selecting items and finishing transactions.*

- [ ] **The Register (POS Screen)**
    - [ ] Build a **Product Picker** grid or list to add items to a "Cart."
    - [ ] Build a **Cart Summary** showing the subtotal and taxes.
    - [ ] Build a **Checkout Workflow** to select payment method (Cash/Card) and "Finish Sale."
- [ ] **Sales Records**
    - [ ] Build an **Orders History** table showing all past transactions.
    - [ ] Build a **Digital Receipt** view (a clean, printable invoice layout).
- [ ] **Customer Profiles**
    - [ ] Build a **Customer List** (Name, Phone, Email).
    - [ ] Build a simple **Purchase History** view for each customer.

## 👥 Phase 4: Team & Permissions
*Focus: Allowing staff to help run the store with limited access.*

- [ ] **Staff Management**
    - [ ] Build an **Invite Employee** form (Sends an email or creates a login).
    - [ ] Build an **Employee List** for the owner to manage staff.
- [ ] **Fixed Role Access**
    - [ ] **Owner:** Access to Dashboard, Settings, and Billing.
    - [ ] **Manager:** Access to Inventory, Customers, and Orders.
    - [ ] **Cashier:** Access **ONLY** to the POS/Register and Customer creation.

## 💰 Phase 5: SaaS Monetization
*Focus: Turning the app into a business.*

- [ ] **Pricing Screen**
    - [ ] Build a page showing the **Free vs. Pro** tiers (e.g., Pro allows more staff or products).
- [ ] **Payment Integration**
    - [ ] Add a **Subscribe Now** button that connects to Stripe Checkout.
- [ ] **Subscription Guard**
    - [ ] Build a simple check to alert the user if their trial is ending or payment failed.

---

## 🛑 Out of Scope (For Now)
*Do not build these until the above phases are 100% complete:*
- ❌ **HR Systems:** No payslips, attendance, or shifts.
- ❌ **Messaging:** No internal chat or MongoDB integration.
- ❌ **Complex RBAC:** No custom permission editors — stick to the 3 roles.
- ❌ **Other Industries:** No Hotel, Restaurant, or Spa features.