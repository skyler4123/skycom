# Skycom API Error Response Format

## Rule

All backend error responses **MUST** use `errors` (plural array), never `error` (singular).

```ruby
# ✅ CORRECT — frontend toast displays "Insufficient stock"
render json: { errors: ["Insufficient stock"] }, status: :unprocessable_entity

# ❌ WRONG — frontend toast shows generic "Failed to..." fallback
render json: { error: "Insufficient stock" }, status: :unprocessable_entity
```

## Why

The `fetchJson` helper (`app/javascript/controllers/helpers/ui_helpers.js:64`) reads the response and attaches `error.errors` to the thrown Error object. All frontend catch blocks use `error.errors?.join(", ")` to display error messages:

```javascript
// ui_helpers.js — fetchJson error handling
const errorData = await response.json().catch(() => ({}));
const error = new Error(errorData.message || `HTTP error! status: ${response.status}`);
error.errors = errorData.errors;  // ← reads "errors" (plural)
throw error;

// In every controller's catch block:
toast({ type: "error", message: error.errors?.join(", ") || "Failed to..." })
```

When the backend returns `{ error: "..." }` (singular), `errorData.errors` is `undefined`, so the catch block always falls through to the generic fallback message.

## Examples

```ruby
# Guard clauses
render json: { errors: ["feature_key required"] }, status: :unprocessable_content
render json: { errors: ["Unauthorized"] }, status: :forbidden
render json: { errors: ["Role not found"] }, status: :not_found

# With additional context
render json: { errors: ["Insufficient stock"], failed_item: result[:failed_item] }, status: :unprocessable_entity
```

## Status Code Conventions

| Status | Symbol | Usage |
|--------|--------|-------|
| 422 | `:unprocessable_content` | Validation errors, business logic failures |
| 403 | `:forbidden` | Authorization failures |
| 404 | `:not_found` | Record not found |
| 500 | `:internal_server_error` | Unexpected errors |

## Enforcement

- Lint: `bin/rubocop` enforces array bracket spacing for `errors: [...]`
- Test: All request specs assert `body["errors"]` with `contain_exactly`, never `body["error"]`
