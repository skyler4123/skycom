# Company Creation Modal - Design Spec

## Overview

Add a "New Company" navigation item on the home page that opens a modal to create a new company. After successful creation, show a toast with a clickable link to the new company's dashboard.

## User Flow

1. User is on home page with "My Companies" nav
2. User clicks "New Company" nav item
3. Modal opens with company creation form
4. User fills form and submits
5. On success: modal closes, toast shows company name as link to dashboard
6. User can click the link to navigate to `/companies/:id/dashboards`

## UI/UX Specification

### Navigation Item
- Location: Sidebar header, next to "My Companies"
- Label: "New Company"
- Icon: `add_circle` (material symbols)

### Modal Structure
- Container: `w-[500px]`, centered, rounded corners
- Header: "Create New Company" title with close button
- Body: Form fields in vertical stack
- Footer: Cancel and Submit buttons

### Form Fields
| Field | Input Type | Required | Notes |
|-------|-----------|---------|-------|
| Name | text input | Yes | Company name, placeholder "My Company" |
| Business Type | select dropdown | Yes | Options: retail, service, hospitality, manufacturing, other |
| Currency | select dropdown | Yes | Options: USD, EUR, GBP, VND, etc. |
| Phone | text input | No | Contact phone, placeholder "+1 234 567 8900" |

### Toast on Success
- Type: success
- Message: "Company [name] created! [Go to Dashboard →]"
- Link: `<a>` tag pointing to `company_dashboards_path(new_company.id)`
- Clicking link navigates to dashboard

## Data Flow

### Form Submission
- Endpoint: `POST /companies`
- CSRF: Injected via `form()` helper
- Format: Standard Rails nested params (`company[name]`, etc.)

### Success Response
- Expected: JSON with created company `{ id: "...", name: "...", ... }`
- On success: close modal, show toast with link

### Error Handling
- Show validation errors in toast (warning type)
- Keep modal open on error

## Technical Implementation

### Files Modified
1. `app/javascript/controllers/layout_controller.js` - Add "New Company" nav item
2. `app/javascript/controllers/companies/new_modal_controller.js` - New modal controller

### Backend (Existing)
- Reuse existing `CompaniesController#create`
- Validations handled by Company model

### Dependencies
- `openModal()` - Opens SweetAlert2 modal
- `form()` helper - Renders form with CSRF
- `company_dashboards_path()` - URL helper for link

## Stimulus Controller

### Class Name
`Companies_NewModalController`

### Identifier
`companies--new-modal`

### File
`app/javascript/controllers/companies/new_modal_controller.js`

### Lifecycle
- `connect()`: Render modal HTML

### Methods
- `modalHTML()`: Return form HTML string
- `submit(event)`: Handle form submission (inherited from form_controller)

## Acceptance Criteria

1. [ ] "New Company" nav item visible on home page sidebar
2. [ ] Clicking nav opens modal with form
3. [ ] Form has: name, business_type, currency_code, phone_number fields
4. [ ] Submit creates company via API
5. [ ] Success: modal closes, toast shows with link to dashboard
6. [ ] Clicking link navigates to `/companies/:id/dashboards`
7. [ ] Form validation errors show on failure