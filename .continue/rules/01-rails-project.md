# Ruby on Rails Project Guidelines

This is a standard Ruby on Rails application (likely Rails 7+).

## Project Structure
- `app/models/` - ActiveRecord models
- `app/controllers/` - Controllers (API or web)
- `app/views/` - ERB or other templates
- `app/services/` or `app/interactors/` - Business logic
- `app/jobs/` - Background jobs (Sidekiq, etc.)
- `app/mailers/` - Mailers
- `config/routes.rb` - All routes
- `db/schema.rb` or `db/structure.sql` - Database schema
- `app/api/` or `app/graphql/` - If using Grape, GraphQL, etc.

## Coding Conventions
- Follow Rails conventions (plural table names, etc.)
- Use strong parameters in controllers
- Prefer service objects for complex logic
- Write tests in `test/` or `spec/` (RSpec/Minitest)
- Use `frozen_string_literal: true` when possible

When editing code:
- Always respect existing style and patterns
- Prefer `find_by!` / `find!` when record must exist
- Use `present?` / `blank?` instead of checking nil + empty