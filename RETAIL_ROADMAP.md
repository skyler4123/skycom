# Skycom Retail Vertical: Detailed Development Roadmap

This document provides a focused, step-by-step roadmap for building out the "Retail" vertical of the Skycom application. The goal is to start with a Minimum Viable Product (MVP) and incrementally add features to create a comprehensive retail management solution.

---

## Phase 1: Retail MVP - Core Sales & Operations

**Goal:** Establish the absolute essentials for a single-location retail business to manage products, customers, and sales. This phase validates the core architecture and deployment pipeline.

1.  **Project Setup (Prerequisite):**
    *   Ensure CI pipeline (`.github/workflows/ci.yml`) is passing.
    *   Successfully deploy a "hello world" app using Kamal (`config/deploy.yml`).

2.  **Core Data Models:**
    *   `User`: Implement basic email/password authentication (`has_secure_password`). A user represents an employee/salesperson.
    *   `Product`: Create the model with essential fields: `name`, `price`, `sku`.
    *   `Customer`: Create the model with `name` and `email`.
    *   `Order`: The central model connecting everything. It should belong to a `User` (salesperson) and a `Customer`, and have many `OrderItems` (which link to `Product`s).

3.  **Basic UI & Workflow (under `/retail` namespace):**
    *   Create a `Retail` namespace for all related controllers.
    *   Build simple CRUD (Create, Read, Update, Delete) interfaces for Products and Customers.
    *   Develop a basic, multi-step order creation form:
        1.  Select a Customer.
        2.  Add Products to the order (with quantity).
        3.  Review and save the order.
    *   A simple page to list all past orders.

> **End of Phase 1 Goal:** A user can log in, manage products and customers, and create a complete order. The application is live on a server.

---

## Phase 2: Management Dashboard & Inventory Control

**Goal:** Empower the business owner/manager with insights and tools to manage inventory and view performance.

1.  **Management Dashboard (`Retail::Management` namespace):**
    *   Create a `Retail::Management::DashboardController`.
    *   Display key metrics using `ApexCharts`:
        *   Total sales (today, this week, this month).
        *   Number of orders.
        *   New customers.
    *   Show a list of recent orders.

2.  **Inventory Management:**
    *   Implement the `Inventory` model to track stock levels for each `Product`.
    *   When an `Order` is completed, automatically decrement the stock level of the associated products.
    *   Create a UI in the management area to view current stock levels and manually adjust them.
    *   Add a "low stock" indicator on the inventory page.

3.  **Product Enrichment:**
    *   Implement the `Brand` model and associate it with `Product`.
    *   Allow products to be categorized, perhaps using the `Tag` model for flexibility (e.g., 'menswear', 'electronics').

> **End of Phase 2 Goal:** A manager can log in, see a snapshot of the business on a dashboard, and perform basic inventory management.

---

## Phase 3: Point of Sale (POS) & Advanced Sales Features

**Goal:** Create a fast, efficient interface for in-store sales and introduce more complex business logic.

1.  **POS Interface (`Retail::Pos` namespace):**
    *   Design a single-screen interface optimized for quick order creation.
    *   Use Hotwire (Turbo Frames/Streams) to update the order summary dynamically as products are added or removed, without page reloads.
    *   Implement a product search feature (by name or SKU) for quickly adding items to the cart.

2.  **Handling Payments:**
    *   Implement the `Payment` and `PaymentMethod` models.
    *   In the POS interface, allow the salesperson to record a payment against an order, specifying the method (e.g., 'Cash', 'Credit Card'). This is for record-keeping initially, not processing actual payments.

3.  **Polymorphic Appointments:**
    *   Implement the polymorphic `Appointment` model.
    *   Create a retail-specific use case: booking a "Personal Shopping" session with an `Employee` (a type of `User`). This validates the polymorphic architecture within the retail context.

> **End of Phase 3 Goal:** A salesperson can use a dedicated POS screen for rapid checkouts. The system can now handle scheduled customer appointments.

---

## Phase 4 & Beyond: Analytics, Customer Engagement & Scaling

**Goal:** Provide deeper business insights and add features for growth and customer retention.

1.  **Reporting & Analytics:**
    *   Build a dedicated `Reports` section in the management namespace.
    *   **Sales Reports:** By date range, by product, by brand, by employee.
    *   **Inventory Reports:** Stock value, low stock alerts.

2.  **Customer Relationship Management (CRM):**
    *   Enhance the `Customer` view to show complete order history.
    *   Use the `Tag` model to segment customers (e.g., 'VIP', 'Lapsed').

3.  **Advanced Features (Future):**
    *   **Purchasing:** Implement `Purchase` model to track incoming stock orders from suppliers.
    *   **Promotions:** A system for creating discounts or special offers.
    *   **Multi-Branch:** Extend models to support multiple `Company` or `Facility` locations.
    *   **Permissions:** Use `Role` and `Policy` models to define different access levels (e.g., 'Salesperson' vs. 'Manager').