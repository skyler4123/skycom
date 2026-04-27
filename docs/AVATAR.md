# Skycom Avatar System

## 1. Overview

Skycom implements an avatar system using Active Storage for backend storage and a Stimulus controller for frontend handling. Users can view and update their avatar through a consistent interface.

---

## 2. Architecture

The avatar system consists of three main components:

| Component | File | Responsibility |
|-----------|------|---------------|
| **Helper** | `ui_helpers.js` (line 623) | Generates avatar HTML markup |
| **Controller** | `avatar_controller.js` | Handles file selection and upload |
| **Backend** | `User::AvatarConcern` | Manages Active Storage attachment |

---

## 3. Frontend Helper (`avatar()`)

**File**: `app/javascript/controllers/helpers/ui_helpers.js`

The `avatar()` helper generates HTML for displaying and optionally updating avatars.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | Yes | URL of the avatar image |
| `isEditable` | boolean | No | If true, enables click-to-edit (default: false) |
| `updateUrl` | string | No | Endpoint for avatar upload (default: "/update_avatar") |
| `paramName` | string | No | Form param key (e.g., "user[avatar_attachment]") |
| `method` | string | No | HTTP method for upload (default: "PATCH") |
| `attributes` | string | No | Additional HTML attributes for root element |
| `html` | string | No | Additional HTML to render (e.g., popover) |

### Usage Examples

**Read-only avatar:**
```javascript
${avatar({
  url: currentUser().avatar,
  attributes: `id="user_avatar" title="${currentUser().name}"`
})}
```

**Editable avatar (with upload):**
```javascript
${avatar({
  url: currentUser().avatar,
  isEditable: true,
  updateUrl: Helpers.users_update_avatar_path(),
  paramName: "user[avatar_attachment]",
  attributes: `id="user_avatar_${currentUser().id}"`
})}
```

---

## 4. Frontend Controller (`AvatarController`)

**File**: `app/javascript/controllers/avatar_controller.js`

### Static Targets

| Target | Description |
|--------|-------------|
| `input` | Hidden file input element |
| `image` | The avatar image element |

### Static Values

| Value | Type | Description |
|-------|------|-------------|
| `uploadUrl` | String | Endpoint for uploading avatar |
| `paramName` | String | Form parameter name (e.g., "user[avatar_attachment]") |
| `method` | String | HTTP method (default: "PATCH") |

### Methods

#### `browse()`
Opens the hidden file input when user clicks on the avatar.

```javascript
browse() {
  this.inputTarget.click()
}
```

#### `upload(event)`
Handles file selection and upload:

1. **Instant Preview**: Reads selected file as DataURL and shows in `imageTarget`
2. **Upload**: Sends FormData to server via `fetchJson`
3. **Update**: Replaces preview with real URL from server response

```javascript
async upload(event) {
  const file = event.target.files[0]
  if (!file) return

  // 1. Instant Local Preview
  const reader = new FileReader()
  reader.onload = (e) => { this.imageTarget.src = e.target.result }
  reader.readAsDataURL(file)

  // 2. Prepare Generic FormData
  const formData = new FormData()
  formData.append(this.paramNameValue, file)

  try {
    const response = await fetchJson(this.uploadUrlValue, {
      method: this.methodValue,
      body: formData
    })

    // 3. Update with the real processed URL from the server
    if (response.url) {
      this.imageTarget.src = response.url
    }
    
    toast({ type: "success", message: response.message || "Updated successfully" })
  } catch (error) {
    toast({ type: "error", message: error.errors?.join(", ") || "Upload failed" })
  }
}
```

---

## 5. Backend Model (`User::AvatarConcern`)

**File**: `app/models/concerns/user/avatar_concern.rb`

### Active Storage Variants

The model defines multiple variants for different use cases:

| Variant | Dimensions | Use Case |
|---------|------------|----------|
| `thumb` | 50x50 | Small icons |
| `medium` | 150x150 | Medium display |
| `profile` | 300x300 | User profile page |
| `full` | 800x800 | High-res display |

### Validation

```ruby
# File size: max 500KB
unless avatar_attachment.blob.byte_size <= 500.kilobytes
  errors.add(:avatar_attachment, "is too big (500KB)")
end

# Content types: JPEG or PNG only
acceptable_types = [ "image/jpeg", "image/png" ]
```

### Methods

| Method | Description |
|--------|-------------|
| `avatar_url(variant)` | Returns URL for a specific variant |
| `update_avatar` | Copies the profile variant URL to the `avatar` column |

---

## 6. Backend Controller (`Users::AvatarConcern`)

**File**: `app/controllers/users/avatar_concern.rb`

### Route

```
PATCH /users/update_avatar
```

### Action

```ruby
def update_avatar
  if current_user.update(avatar_params)
    current_user.update_avatar
    current_user.refresh_cache
    render json: { 
      url: current_user.avatar_url(:profile),
      message: "Avatar updated!" 
    }
  else
    render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
  end
end
```

### Response

**Success**:
```json
{
  "url": "/rails/active_storage/disk/...",
  "message": "Avatar updated!"
}
```

**Error**:
```json
{
  "errors": ["Avatar is too big (500KB)"]
}
```

---

## 7. Frontend Helper Function

**File**: `app/javascript/controllers/helpers/url_helpers.js`

```javascript
export const users_update_avatar_path = () => `/users/update_avatar`
```

---

## 8. Usage in Header

**File**: `app/javascript/controllers/home/header/authentication_controller.js`

```javascript
${avatar({
  url: currentUser().avatar,
  attributes: `id="user_avatar_${currentUser().id}" title="${currentUser().name}"`,
  ...
})}
```

---

## 9. Avatar in Popover

**File**: `app/javascript/controllers/users/avatar_popover_controller.js`

When an editable avatar needs a popover menu (e.g., for profile options), render the popover in the `html` parameter:

```javascript
${avatar({
  url: currentUser().avatar,
  isEditable: true,
  updateUrl: Helpers.users_update_avatar_path(),
  paramName: "user[avatar_attachment]",
  html: `<div data-controller="users--avatar-popover"></div>`
})}
```

---

## 10. Best Practices

1. **Always use `avatar()` helper** - Never manually write `<img>` tags for avatars
2. **Provide fallback URL** - Handle cases where avatar is not yet set
3. **Use appropriate variant** - `profile` (300x300) for most displays
4. **Handle errors gracefully** - Show toast notifications on failure

---

*End of file*