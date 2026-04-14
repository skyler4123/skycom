# SKYCOM Technical Standards

## URL & Controller Structure
- **Admin**: `/companies/:company_id/{resource}`
- **Site Views**: `/companies/:company_id/{view_version}/{resource}`
- **Example**: `/companies/5/pos_v1`

## Stimulus Naming Convention
Follow the structure defined in `AGENT.md`:
- File: `app/javascript/controllers/companies/pos_v1/index_controller.js`
- Class: `Companies_PosV1_IndexController`
- Identifier: `companies--pos-v1--index`

## JavaScript Patterns
- **NEVER** use native `fetch()`. Always use `window.Helpers.fetchJson(url, options)`.
- Use `toast()` for success/error notifications.
- Use `openModal(html)` for SweetAlert2 integration.

## Database Rules
- Every table belongs to a `company_id`.
- Most business tables (Products, Orders) belong to a `branch_id`.
- Use `jsonb` for flexible attributes to avoid schema bloat across industries.