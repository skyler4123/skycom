# Skycom Application Development Roadmap

This document outlines a strategic roadmap for the development of the Skycom application, based on the vision in `BUSINESS.md`. The goal is to build momentum by delivering value incrementally, testing architectural assumptions, and ensuring a solid foundation before adding complexity.

## Project Management Foundation

Before diving into code, it's crucial to set up a system to manage your work. A simple project board will be incredibly effective.

1.  **Choose a Tool:** Use a Kanban-style board like GitHub Projects, Trello, or Jira.
2.  **Create Columns:** Start with simple columns: `Backlog`, `To Do`, `In Progress`, and `Done`.
3.  **Populate the Backlog:** Turn the features and tasks from the roadmap below into individual "cards" or "issues" and place them in the `Backlog`. This is your master list of everything you want to build.
4.  **Plan Sprints:** Each week, move a small, manageable number of cards from the `Backlog` into the `To Do` column. This is your goal for the week. This process prevents you from getting sidetracked and helps you focus on what's most important *now*.

---

## Phased Development Roadmap

This roadmap breaks the project into logical phases. Each phase builds upon the last, ensuring your core architecture is solid before you add complexity.

### Phase 1: Core Foundation & Minimum Viable Product (MVP)

**Goal:** Get the essential, non-negotiable features built and deployed. The aim here is to validate your core idea with the simplest possible version of one vertical.

1.  **Setup & Deployment:**
    *   **Priority 1:** Configure and run your CI pipeline (`.github/workflows/ci.yml`). A green build should be your baseline.
    *   **Priority 2:** Get your Kamal deployment (`config/deploy.yml`) working. Deploy a "hello world" version of your app to your server. Deploying early and often makes it a routine, not a dreaded task.

2.  **Core Model Implementation:**
    *   Focus on the absolute essentials for a single user to do something useful.
    *   **Users & Authentication:**
        *   Build the `User` model.
        *   Implement standard registration (`/sign_up`) and login (`/sign_in`) with email/password. Use Rails' built-in `has_secure_password`.
    *   **First Vertical (Retail):**
        *   Build the `Product` model (with just a name and price).
        *   Build the `Customer` model (with just a name and email).
        *   Build a simple `Order` model that connects a `User` (as the salesperson), a `Customer`, and `Product`s.

3.  **Basic UI:**
    *   Create a simple, namespaced area for `/retail`.
    *   Build the forms and pages to create/view products, customers, and orders. Don't worry about making it beautiful yet; focus on functionality.

> At the end of this phase, a single user should be able to log in, create a customer, define a product, and record a simple order. You will have validated your deployment process and core data relationships.

---

### Phase 2: Flesh out the First Vertical (Retail)

**Goal:** Make the Retail vertical genuinely useful and begin introducing the richer, polymorphic models you've planned.

1.  **Enhance Retail Management:**
    *   Implement the `Inventory`, `Brand`, and `Purchase` models.
    *   Build out the `Retail::Management` namespace controllers.
    *   Create a dashboard (`Retail::Management::DashboardController`) that shows key metrics. Use `ApexCharts` for some initial visualizations.

2.  **Introduce Polymorphic Models:**
    *   Implement the `Appointment` model. Make it polymorphic (`appointable`).
    *   Create an `Employee` model (which can be a type of `User`).
    *   Build a feature to book an appointment with an `Employee` or for a specific `Product` (e.g., a product demo). This will be the first real test of your polymorphic architecture.

3.  **Improve User Experience:**
    *   Integrate `SweetAlert2` for better user feedback on actions (e.g., "Order created successfully").
    *   Refine your forms and UI using Hotwire to make the experience smoother.

4.  **Strengthen Testing:**
    *   Your CI pipeline is running, now make it more robust. Write system tests for the user flows you've built. Ensure your test environment in `database.yml` is correctly configured.

> At the end of this phase, the Retail vertical will feel like a real application. You will have proven that your polymorphic `Appointment` model works, which is a critical architectural milestone.

---

### Phase 3: Prove the Multi-Vertical Architecture

**Goal:** Add the second business vertical (`Education`) to prove the flexibility and reusability of your core models.

1.  **Create the Education Vertical:**
    *   Create the `Education` namespace for controllers and routes.
    *   Build the `Course` model (can be a type of `Service`).
    *   Use the existing `Customer` model for `Students` and the `Employee` model for `Teachers`.
    *   Reuse the polymorphic `Appointment` model for `Classes` or `Schedules`.

2.  **Refactor for Generality:**
    *   As you add the Education vertical, you will likely find places where your code made assumptions about "Retail".
    *   This is expected! Take this opportunity to refactor views, controllers, or helpers to be more generic, so they can be shared easily between verticals.

3.  **Implement Education-Specific Features:**
    *   Build the basic UI for managing courses, students, and teachers within the `/education` namespace.

> At the end of this phase, you will have two distinct business verticals running on the same core set of models. This is the ultimate validation of your vision and sets you up for future expansion.

---

### Phase 4 & Beyond: Expand and Scale

**Goal:** Continue adding features and verticals, and begin thinking about scalability and long-term maintenance.

1.  **Add the Hospital Vertical:**
    *   Repeat the process from Phase 3 for the `Hospital` module, reusing core models for `Patients`, `Doctors`, and `Appointments`.

2.  **Implement Advanced Core Features:**
    *   Tackle the remaining core models from your business plan: `Project`/`Task`, `Notification`, `Tag`, `Exam`, etc.
    *   Build out the advanced authentication features: OmniAuth, passwordless login, and invitations.

3.  **Optimize for Production:**
    *   **Database:** Your `database.yml` is set up for PostgreSQL in production. Ensure you have a solid backup and maintenance plan.
    *   **Background Jobs:** Your `deploy.yml` correctly notes that `SolidQueue` should eventually be moved to a dedicated job server. When you see background job processing slowing down your web requests, it's time to make that move.
    *   **File Storage:** Your `storage.yml` is configured for `local` disk. For production, you should strongly consider switching to a service like Amazon S3 or MinIO to handle file uploads, as noted in `deploy.yml`'s `volumes` section. This prevents data loss if your server fails.