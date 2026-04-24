# 🚀 Project Roadmap: Multi-Tenant Business Management System

This roadmap outlines the development phases for a comprehensive SaaS platform, focusing on multi-tenancy, granular RBAC (Role-Based Access Control), and industry-specific business views.

---

## 🏗️ Phase 1: Authentication & Multi-Tenancy Foundation
*Goal: Establish secure access and the "Company Namespace" architecture.*

- [ ] **Identity Management**
    - [ ] User Sign Up / Sign In / Sign Out.
    - [ ] Profile management.
- [ ] **Company Orchestration**
    - [ ] Create Company (The "Namespace" for all resources).
    - [ ] **Auto-Provisioning:** Automatically create an `Employee` record for the creator with the role of `Owner`.
- [ ] **Namespace Logic**
    - [ ] Implement middleware to scope every database query by `company_id`.
    - [ ] Ensure data isolation between different companies.

## 🔐 Phase 2: RBAC & Governance
*Goal: Move from User-level permissions to Employee/Role-level permissions.*

- [ ] **Role Management**
    - [ ] CRUD for `Roles` within a company.
    - [ ] CRUD for `Policies` (specific permissions like `create_order`, `view_payslip`).
- [ ] **Policy Appointment**
    - [ ] Logic to attach policies to roles.
    - [ ] Logic to appoint roles to employees.
- [ ] **Access Control**
    - [ ] Global permission checker based on the "Employee's Role" rather than the "User account."

## 📦 Phase 3: Core Resource Management (The CRUD Engine)
*Goal: Build the fundamental modules required for business operations.*

### 👥 Human Resources (HR)
- [ ] **Branch & Department:** Organize the company structure.
- [ ] **Employee:** Complete management of staff.
- [ ] **Attendance:** Clock-in/out tracking.
- [ ] **Payslip:** Payroll generation and history.

### 🏺 Inventory & Catalog
- [ ] **Product:** Physical goods (SKU, stock levels).
- [ ] **Service:** Non-physical offerings (e.g., Massage, Cleaning).
- [ ] **Facility:** Manage company assets (e.g., Rooms, Equipment).
- [ ] **Inventory:** Stock tracking, adjustments, and movements.

### 💳 Sales & CRM
- [ ] **Customer:** CRM profile management.
- [ ] **Booking:** Scheduling for services or facilities.
- [ ] **Order:** Transaction processing.
- [ ] **Payment & Invoice:** Financial record-keeping and billing.
- [ ] **Subscription:** Recurring billing for customers within the company.

## 💬 Phase 4: Communication & Intelligence
*Goal: Enhance collaboration and data-driven decision-making.*

- [ ] **Chat System**
    - [ ] Integration with **MongoDB** for high-concurrency messaging.
    - [ ] Real-time communication between employees.
- [ ] **Company Reporting**
    - [ ] Dashboard for sales, attendance, and inventory health.

## 💰 Phase 5: System Monetization (SaaS Layer)
*Goal: Manage the platform's own revenue and company oversight.*

- [ ] **SystemSubscription**
    - [ ] Implementation of tiers based on usage (e.g., number of employees or orders).
    - [ ] Automated billing/charging for the "Owner User."
- [ ] **SystemReport**
    - [ ] High-level reporting of company activity to the system admins.

## 🏢 Phase 6: Industry-Specific "Verticals"
*Goal: Provide tailored User Experiences for specific business types.*

- [ ] **Retail View (Priority)**
    - [ ] Optimized POS (Point of Sale) interface.
    - [ ] Fast checkout workflow for cashiers.
- [ ] **Future Expansions**
    - [ ] **Hotel:** Room status and check-in/out management.
    - [ ] **Restaurant:** Table management and kitchen workflow.
    - [ ] **Services (Tax/HR):** Specialized document and task management.

---

## 🛠️ Technical Stack Reference
* **Core:** Relational DB (PostgreSQL/MySQL) for structured resources.
* **Chat:** MongoDB for flexible, fast messaging.
* **Architecture:** Multi-tenant (Shared Database, Discriminator Column `company_id`).