# Skycom API Response Convention

## Overview

All `create`, `update`, and `destroy` actions must return responses in a standardized format to enable consistent frontend handling. This ensures the FormController and CheckboxController can properly toast messages and dispatch success events.

## Response Structure

All mutation endpoints must return JSON with exactly **three keys**:

| Key | Type | Description |
|-----|------|-------------|
| `status` | String | Either `"success"` or `"error"` |
| `message` | String | Human-readable message for toast notification |
| `data` | Object/Array/null | The resource or null for destroy |

---

## HTTP Status Mapping

| Action | Success HTTP | Error HTTP |
|--------|------------|-----------|
| `create` | `201 Created` | `422 Unprocessable Entity` |
| `update` | `200 OK` | `422 Unprocessable Entity` |
| `destroy` | `200 OK` | `422 Unprocessable Entity` |

---

## Examples

### Create - Success

```ruby
def create
  @product = Product.new(product_params)
  
  if @product.save
    render json: { 
      status: "success", 
      message: "Product created successfully!", 
      data: @product 
    }, status: :created
  else
    render json: { 
      status: "error", 
      message: "Validation failed", 
      data: @product.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
```

### Update - Success

```ruby
def update
  @product = current_company.products.find(params[:id])
  
  if @product.update(product_params)
    render json: { 
      status: "success", 
      message: "Product updated successfully!", 
      data: @product 
    }
  else
    render json: { 
      status: "error", 
      message: "Update failed", 
      data: @product.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
```

### Destroy - Success

```ruby
def destroy
  @product = current_company.products.find(params[:id])
  @product.destroy!
  
  render json: { 
    status: "success", 
    message: "Product deleted successfully!", 
    data: nil
  }
end
```

---

## Frontend Integration

### FormController

The `form_controller.js` automatically handles these responses:

```javascript
// form_controller.js lines 67-88
if (response && (response.status === "success" || response.id)) {
  toast({ 
    type: "success", 
    message: response?.message || "Successfully saved" 
  })
  // ... close modal and dispatch success
} else {
  throw new Error(response?.message || "Validation failed")
}
```

**Requirements:**
1. Response must have `status: "success"` for success toast
2. Response must include `message` for the toast content
3. On error, the message is caught and displayed as error toast

### CheckboxController

The `checkbox_controller.js` also uses this format:

```javascript
// checkbox_controller.js lines 51-54
toast({ type: "success", message: response?.message || "Updated successfully!" })
// ...
toast({ type: "error", message: error?.message || "Update failed." })
```

---

## Error Handling Patterns

### ActiveRecord::RecordInvalid

```ruby
rescue ActiveRecord::RecordInvalid => e
  render json: { 
    status: "error", 
    message: "Validation failed", 
    data: e.record.errors.full_messages 
  }, status: :unprocessable_entity
```

### ActiveRecord::RecordNotFound

```ruby
rescue ActiveRecord::RecordNotFound
  render json: { 
    status: "error", 
    message: "Product not found", 
    data: nil 
  }, status: :not_found
```

### Generic Error

```ruby
rescue => e
  render json: { 
    status: "error", 
    message: e.message, 
    data: nil 
  }, status: :internal_server_error
```

---

## Checklist

Before marking a feature complete, verify:

- [ ] All `create` actions return `{ status, message, data }`
- [ ] All `update` actions return `{ status, message, data }`
- [ ] All `destroy` actions return `{ status, message, data: nil }`
- [ ] All error responses include `status: "error"` and `message`
- [ ] Frontend displays the `message` via toast notification