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

## System Fields Block (Mandatory for All Business Tables)

Every table that represents business logic (products, orders, customers, appointments, etc.) **must** include the System Fields block just above `t.timestamps`. This ensures consistent tracking, soft-delete, metadata, and permissions across all entities.

### Required Block

```ruby
# --- System Fields ---
t.integer  :lifecycle_status
t.integer  :workflow_status
t.integer  :business_type
t.datetime :expiration_date
t.jsonb    :metadata,       default: {}
t.datetime :discarded_at,   index: true
t.string   :permission_resource_name
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `lifecycle_status` | integer | Active record lifecycle (e.g., active, archived, deleted) |
| `workflow_status` | integer | Workflow step (e.g., pending, approved, rejected) |
| `business_type` | integer | Industry-specific type (e.g., retail, education, gym) |
| `expiration_date` | datetime | When this record expires (nullable) |
| `metadata` | jsonb | Flexible JSON storage for extra attributes |
| `discarded_at` | datetime | Soft-delete timestamp (with `index: true`) |
| `permission_resource_name` | string | ABAC permission resource identifier |

### Placement

The System Fields block **must** be placed just above `t.timestamps`, after all business-specific columns and before Rails timestamps.

### Example

```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :code, index: true
      t.decimal :price

      # --- System Fields ---
      t.integer  :lifecycle_status
      t.integer  :workflow_status
      t.integer  :business_type
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
  end
end
```

### Index Rule

The `discarded_at` column uses inline `index: true` — **do NOT** add a separate `add_index` line for `discarded_at`. The inline index is sufficient.

### Skip For

- Reference tables (Periods, Prices, Addresses) — immutable, no system fields
- Gem/Rails migrations (Active Storage, Sessions, PaperTrail)
- Pure join tables without business fields (only polymorphic refs + name/description/code)