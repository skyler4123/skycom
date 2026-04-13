# SKYCOM Master Roadmap

| ID | Tag | Task Name | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **SKYCOM-001** | `[PLAT]` | **Backend Auth Hook** | Enforce Role/Resource permissions in the controller layer (Logic exists in UI, needs enforcement). | 🔴 Todo |
| **SKYCOM-002** | `[PLAT]` | **Tenant Scoping** | Global `current_company` and `current_branch` scoping for all DB queries. | 🔴 Todo |
| **SKYCOM-003** | `[INV]` | **Product Schema** | Create `Product` model with `jsonb` for industry-specific metadata. | 🔴 Todo |
| **SKYCOM-004** | `[INV]` | **Admin Product CRUD** | Build the UI to manage the shared product catalog in the Admin Dashboard. | 🔴 Todo |
| **SKYCOM-005** | `[POS1]` | **POS v1 Shell** | Build the `/companies/:id/pos_v1` site view layout and persona. | 🟡 Next |
| **SKYCOM-006** | `[POS1]` | **Checkout Logic** | Create Orders/LineItems and deduct stock upon sale completion. | 🟡 Next |
| **SKYCOM-007** | `[PLAT]` | **Traefik Header Routing** | Configure Traefik for Swarm to route traffic to specific nodes via headers. | ⚪ Future |
| **SKYCOM-008** | `[HR]` | **Attendance Logic** | Clock-in/out and shift tracking features for the HR module. | ⚪ Future |