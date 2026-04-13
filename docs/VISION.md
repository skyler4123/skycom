# SKYCOM: Platform Vision & Architecture

## 1. Project Essence
A high-performance, modular Business OS (PaaS) built with Rails 8 and Stimulus.
- **Goal**: Provide "Good Enough" horizontal features for all industries (Retail, F&B, HR, Service).
- **Core Strategy**: A single "Admin" Source of Truth (SSoT) re-skinned via context-specific "Site Views" (e.g., POS, Kitchen, Staff).

## 2. Technical Manifesto
- **Backend**: Rails 8 (Solid Queue/Cache/Cable) + PostgreSQL.
- **Frontend**: Stimulus JS (Shell-First SPA logic). No heavy JS frameworks.
- **Multi-Tenancy**: Scoped by `company_id` and `branch_id`.
- **Infrastructure**: Docker Swarm + Portainer.
- **Routing**: Traefik handles traffic isolation via `X-Company-ID` headers to allow node pinning for enterprise clients without subdomain complexity.

## 3. Technical Tags
When discussing or creating tasks, use these tags for context:
- `[PLAT]`: Platform, Auth, Multi-tenancy, Infrastructure.
- `[INV]`: Inventory, Products, Stock management.
- `[POS1]`: Retail Point of Sale Version 1.
- `[HR]`: Human Resources, Employees, Attendance.