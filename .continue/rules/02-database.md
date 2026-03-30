# Database & Models

- Always check `db/schema.rb` for current columns and indexes
- Models inherit from `ApplicationRecord`
- Use scopes for common queries
- Prefer `includes` / `eager_load` / `preload` to avoid N+1 queries