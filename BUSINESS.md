# Skycom: A Flexible Multi-Vertical Business Management Platform

## 1. Vision & Overview

Skycom is a comprehensive, multi-purpose Rails application designed to serve as a centralized management system for a wide variety of business verticals. The core vision is to provide a single, flexible, and scalable platform that can be adapted to the specific needs of different industries, such as retail, education, hospital, restaurant, and fitness.

The application is built upon a highly flexible database architecture that leverages polymorphic associations extensively. This allows core business concepts like "Customers," "Products," "Appointments," and "Invoices" to be shared and reused across different business domains, minimizing code duplication and maximizing adaptability.

## 2. Application Architecture

The application is logically divided into two main parts: a set of **Core Polymorphic Models** and distinct **Business Vertical Modules**.

### 2.1. Core Polymorphic Models

At the heart of Skycom is a rich set of general-purpose resources that are designed to be polymorphic. This means they can be associated with any other model in the application, providing a powerful and flexible foundation.

Key core models include:
- **Users & Access Control:** `User`, `Role`, `Policy`, `Employee`
- **CRM & Scheduling:** `Customer`, `Appointment`, `Booking`, `Schedule`
- **E-commerce & Sales:** `Product`, `Service`, `Order`, `Cart`, `Purchase`, `Invoice`, `Payment`
- **Inventory & Facilities:** `Inventory`, `Brand`, `Facility`
- **Project Management:** `Project`, `Task`
- **Engagement & Communication:** `Notification`, `Event`, `Tag`
- **Education & Exams:** `Exam`, `Question`, `Answer`

The use of "appointment" tables like `product_appointments`, `employee_appointments`, and `tag_appointments` indicates a polymorphic `Appointment` model that can be linked to many other resources. This pattern is repeated across the application, forming the basis of its flexibility.

### 2.2. Business Vertical Modules

To provide a tailored experience for different industries, the application uses namespaces to group controllers and routes into specific business verticals. Each vertical can then extend or utilize the core models in a way that makes sense for its domain.

The currently defined verticals are:

#### a. Retail Management (`/retail`)

This module is designed for managing retail operations. It includes namespaces for both back-office management and Point of Sale (POS) systems.

*   **Namespace:** `Retail`
*   **Controllers:** `Retail::Management::*` and `Retail::Pos::*`
*   **Key Resources:** `Dashboard`, `Branches`, `Products`, `Orders`, `Customers`, `Employees`, `Inventories`, `Sales`, `Reports`.

#### b. Education Management (`/education`)

This module is tailored for educational institutions like schools or universities.

*   **Namespace:** `Education`
*   **Controllers:** `Education::*`
*   **Key Resources:** `Schools`, `Courses`, `Students`, `Teachers`, `Classes`, `Schedules`.

#### c. Hospital Management (`/hospital`)

This module provides functionality for managing healthcare facilities.

*   **Namespace:** `Hospital`
*   **Controllers:** `Hospital::*`
*   **Key Resources:** `Patients`, `Doctors`, `Appointments`, `Medical_Records`, `Prescriptions`, `Departments`, `Billings`, `Labs`, `Pharmacies`.

#### d. Restaurant Management (`/restaurant`)

This module is for managing food and beverage businesses.

*   **Namespace:** `Restaurant`
*   **Controllers:** `Restaurant::*`
*   **Key Resources:** `Menus`, `Tables`, `Reservations`, `Orders`, `Customers`, `Employees`, `Billings`.

#### e. Fitness Management (`/fitness`)

This module is tailored for gyms, fitness centers, and studios.

*   **Namespace:** `Fitness`
*   **Controllers:** `Fitness::*`
*   **Key Resources:** `Members`, `Classes`, `Schedules`, `Trainers`, `Bookings`, `Memberships`.

## 3. Technical Stack & Configuration

### 3.1. Backend

*   **Framework:** Ruby on Rails 8.0
*   **Primary Keys:** The application uses `UUID`s as the primary key type for Active Record models, which is excellent for distributed systems and preventing ID enumeration.
*   **Web Server:** Puma
*   **Background Jobs:** Utilizes `SolidQueue`, a database-backed queuing system for background jobs, which is integrated to run within the Puma process for single-server deployments.
*   **WebSockets:** Employs `SolidCable`, a database-backed backend for Action Cable, ensuring WebSocket messages are persistent.

### 3.2. Frontend

*   **Framework:** Hotwire (Turbo & Stimulus) for modern, fast, and server-rendered frontends.
*   **Package Management:** `importmap-rails` is used to manage JavaScript dependencies without a Node.js toolchain.
*   **Key Libraries:**
    *   `SweetAlert2`: For creating beautiful and responsive alerts.
    *   `Day.js`: A lightweight library for date and time manipulation.
    *   `ApexCharts`: For creating interactive data visualizations and charts.

### 3.3. Authentication

The application features a comprehensive, custom-built authentication system with support for:
*   **Standard Login:** Email and password (`/sign_in`).
*   **User Registration:** Self-service sign-up (`/sign_up`).
*   **Identity Management:** Email verification and password resets under the `/identity` namespace.
*   **OmniAuth:** Integration with third-party providers (e.g., Google, Facebook) via `/auth/:provider/callback`.
*   **Passwordless Login:** Support for passwordless authentication flows.
*   **Invitations:** A system for inviting new users to the platform.

### 3.4. Deployment

*   **Tooling:** The project is configured for deployment using **Kamal**, a tool for deploying containerized web applications.
*   **Configuration (`deploy.yml`):**
    *   **Service Name:** `skycom`
    *   **Proxy:** Configured for a single-server deployment with SSL termination via Let's Encrypt.
    *   **Container Registry:** Set up to pull images from a private container registry.
    *   **Persistence:** Uses a Docker volume (`skycom_storage`) for persistent file storage (e.g., Active Storage).
    *   **Accessories:** The configuration includes commented-out examples for adding accessory services like a MySQL database and Redis.

## 4. How to Use This Document

This document provides a high-level architectural overview of the Skycom application. It is intended to help developers, stakeholders, and automated tools understand:
*   The core purpose and design philosophy of the application.
*   The relationship between the core models and the business-specific modules.
*   The key technologies and libraries used in the stack.

By understanding this structure, developers can more easily navigate the codebase, add new features, or integrate with the system.
