# 🚀 Project Roadmap: Skycom Retail MVP
**Focus:** Speed to Market, Essential Retail POS, and Immediate Value.

---

## 🏗️ Phase 1: The Multi-Tenant Core (Weeks 1-2)
*Goal: Establish the secure "Company Namespace" so users can sign up and own their data.*

- [ ] **Simple Identity Management**
    - [ ] Email/Password Sign-up and Login.
    - [ ] Auto-provisioning: Creating a company makes the user the `Owner`.
- [ ] **Data Isolation (Namespace)**
    - [ ] Implement global scoping: Every query must include `company_id`.
    - [ ] Ensure one user can belong to/manage multiple companies if needed.
- [ ] **Infrastructure Setup**
    - [ ] PostgreSQL only (Keep it simple, no MongoDB yet).
    - [ ] Standardized Tailwind layout (Sidebar + Header).

## 📦 Phase 2: Retail Essentials & The "Attraction" Dashboard (Weeks 3-5)
*Goal: Build the core features customers pay for and the visual hook that sells the app.*

- [ ] **Inventory Lite**
    - [ ] **Products:** Name, SKU, Sale Price, Cost, and Stock Level.
    - [ ] **Low Stock Tracking:** Automatically flag items when stock hits a threshold.
- [ ] **The "Register" (Point of Sale)**
    - [ ] **Order Creation:** Fast selection of products and checkout workflow.
    - [ ] **Payment Recording:** Mark as Cash, Card, or Pending.
    - [ ] **Basic Receipts:** Clean web-view/PDF for the customer.
- [ ] **The MVP Dashboard (Static-First)**
    - [ ] **Revenue Cards:** "Total Sales Today," "Order Count," and "New Customers."
    - [ ] **Low Stock Alert Block:** A clear red list of items that need reordering.
    - [ ] **Top Performers:** List of the top 5 selling products this month.
    - [ ] **Simple Chart:** One "Sales this week" line graph (using Chartkick or similar).
- [ ] **Customer Registry**
    - [ ] Simple CRM profiles: Name, Phone, and Total Spend.

## 🔐 Phase 3: Simple Team Management (Week 6)
*Goal: Allow owners to bring in staff with restricted access.*

- [ ] **Fixed Role System**
    - [ ] **Owner:** Full access (Billing + System Settings).
    - [ ] **Manager:** Inventory management, reports, and customers.
    - [ ] **Cashier:** Register access and customer creation only.
- [ ] **Employee Invites**
    - [ ] Invite staff via email to join the specific company namespace.

## 💰 Phase 4: Monetization & Launch (Weeks 7-8)
*Goal: Turn the project into a real business.*

- [ ] **SaaS Billing (Stripe Integration)**
    - [ ] Implement simple tiers (e.g., Free vs. Pro based on Order volume).
    - [ ] Automated subscription management for the "Owner" user.
- [ ] **System Health & Deployment**
    - [ ] Basic internal admin view to see total active companies.
    - [ ] Production deployment (Heroku/Render/Railway).

---

## 🛑 The "Later" List (Deferred Features)
To ensure we release **NOW**, these are strictly out of scope for the MVP:
- ❌ **Advanced HR:** No Payslips, Attendance, or Schedules.
- ❌ **Custom RBAC:** No granular "Policies"—stick to the 3 fixed roles.
- ❌ **Chat/Messaging:** Use external tools for now.
- ❌ **Multiple Verticals:** No Hotel or Restaurant specific UI.
- ❌ **Modular Dashboard:** The "Block" system is a Phase 5+ enhancement.

---

## 🛠️ Technical Stack
* **Backend:** Ruby on Rails / Stimulus.js.
* **Database:** PostgreSQL.
* **Styling:** Tailwind CSS.
* **Charts:** Simple Server-side rendering (Chartkick/SVG).
* **Payments:** Stripe Billing.