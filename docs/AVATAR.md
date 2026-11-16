# Skycom Avatar System

## 1. Overview

Skycom implements an avatar system using Active Storage for backend storage and a Stimulus controller for frontend handling. Users can view and update their avatar through a consistent interface.

---

## 2. Architecture

The avatar system consists of three main components:

| Component | File | Responsibility |
|-----------|------|---------------|
| **Helper** | `ui_helpers.js` (`avatar()`) | Generates avatar HTML markup |
| **Controller** | `avatar_controller.js` | Handles file selection and upload |
| **Backend** | `User::AvatarConcern` | Manages Active Storage attachment |

---

## 3. Frontend Helper (`avatar()`)

**File**: `app/javascript/controllers/helpers/ui_helpers.js`

The `avatar()` helper generates HTML for displaying and optionally updating avatars. An avatar is editable only when **both** `updateUrl` and `paramName` are present; otherwise it renders read-only and emits no file input.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | No | Current image URL; blank renders the fallback |
| `updateUrl` | string | No | Upload endpoint; omit to make the avatar read-only |
| `paramName` | string | No | Multipart key (e.g., `user[avatar_attachment]`) |
| `method` | string | No | HTTP method for upload (default: `PATCH`) |
| `className` | string | No | Sizing classes for the root element (default: `size-10`) |
| `shape` | string | No | Corner classes (default: `rounded-full`) |
| `fallback` | string | No | HTML for the empty state (e.g., mobile initials) |
| `badge` | boolean | No | Persistent camera badge for touch devices (default: `false`) |
| `reloadOnSuccess` | boolean | No | Reload after upload so client cache and header refresh (default: `false`) |
| `attributes` | string | No | Attributes for the root element (tooltip, id, …) |
| `innerAttributes` | string | No | Attributes for the inner circle (popover, …) |

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
  updateUrl: Helpers.users_update_avatar_path(),
  paramName: "user[avatar_attachment]",
  reloadOnSuccess: true,
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
| `reloadOnSuccess` | Boolean | Clear the client cache and reload after upload (default: false) |

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
3. **Update**: Replaces the preview with the real URL from the server response.
   If the empty state was a fallback `<div>`, it is swapped for an `<img>`.
4. **Failure**: Restores the previous markup and toasts the server `errors`
5. **Reload**: With `reloadOnSuccess`, calls `clearClientCacheAndReload` so the
   header avatar and cached `currentUser().avatar` refresh together

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
    render json: { 
      url: current_user.avatar_url(:profile),
      message: "Avatar updated!" 
    }
  else
    render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
  end
end
```

`User` already runs `after_commit :refresh_cache` on update, so the controller
does not call it (the method is private and the callback owns cache refresh).

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
  "errors": ["Avatar attachment is too big (500KB)"]
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

## 9. Avatar Dropdown Menu

**File**: `app/javascript/controllers/users/avatar_popover_controller.js`

The popover menu holds two items: **Profile** and **Sign Out**. Shared by the
company header (`companies/layout_controller.js`) and the homepage header
(`home/header/authentication_controller.js`), so both behave the same.

**Profile** is a real link (`Helpers.myProfilePath()` from
`controllers/helpers/auth_helpers.js`), never a modal:

| Viewer | Target |
|---|---|
| `admin` / `super_admin` | `/admin/companies` |
| Owner/employee with an employee record | `/companies/:company_id/employees/:employee_id` for the current company, or the first cached employee record on pages without a company (homepage) |
| Any other signed-in user (no employee record) | `/redirect/profile` → homepage with a flash: "You need an employee account of a company to see your profile." |

The sidebar's "My Profile → Employee" item uses the same helper, so the two
links can never disagree.

```javascript
${avatar({
  url: currentUser()?.avatar,
  innerAttributes: popover({
    position: "bottom",
    html: `<div data-controller="users--avatar-popover"></div>`
  })
})}
```

The header avatar is read-only; editing lives on the Profile page.

---

## 10. Profile Pages (web + mobile)

| Page | Controller | Behaviour |
|---|---|---|
| Web employee profile (`/companies/:company_id/employees/:id`) | `app/javascript/controllers/companies/employees/show_controller.js` | Renders `user.avatar` in the identity block. Editable **only** when the employee's linked user is the signed-in user; everyone else sees it read-only. Tooltip: "Change avatar · JPG or PNG, up to 500KB". `reloadOnSuccess: true` clears the client cache and reloads so the header avatar refreshes too. |
| Mobile profile (`/mobile/companies/:company_id/employee`) | `app/javascript/controllers/mobile/companies/employees/show_controller.js` | Self-only page. Shows `user.avatar` with the employee's initials as fallback, a persistent camera badge, and the hint "Tap the photo to change it · JPG or PNG, up to 500KB". Upload updates the image in place and toasts — no reload. |

Payloads:

- Web: `Companies::EmployeesController#format_employee` includes `user.avatar`.
- Mobile: `Mobile::Companies::EmployeesController#profile_payload` includes `user.avatar`.

Both pages post to the same `PATCH /users/update_avatar`; no new endpoint or
migration. Only the signed-in user's own avatar can be changed.

---

## 11. Best Practices

1. **Always use `avatar()` helper** - Never manually write `<img>` tags for avatars
2. **Provide fallback URL** - Handle cases where avatar is not yet set
3. **Use appropriate variant** - `profile` (300x300) for most displays
4. **Handle errors gracefully** - Show toast notifications on failure
5. **Give touch users an affordance** - `badge: true` renders a camera badge; hover overlays are desktop-only
6. **Only own avatar is editable** - The endpoint updates `current_user`, so gate the editor on `user.id === currentUser().id`

---

*End of file*