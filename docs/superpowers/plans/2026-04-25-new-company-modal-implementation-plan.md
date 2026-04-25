# New Company Modal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "New Company" nav button on home page that opens a modal to create a new company via API, then show a toast with a clickable link to the new company's dashboard.

**Architecture:** 
- Home page already has "New Company" button with `data-controller="companies--new-modal"` and `data-action="click->companies--new-modal#openModal"`
- Need to create `Companies_NewModalController` that:
  1. Has `openModal()` method to open the modal dialog
  2. Renders form HTML in modal body (via `connect()` lifecycle)
  3. Handles form submission via native fetch (POST JSON to API)
  4. On success: close modal, show toast with link to dashboard, reload page

**Tech Stack:** 
- Stimulus (controllers)
- SweetAlert2 (modals via `openModal()`)
- Rails JSON API  
- Fetch API (not form_controller for simpler event handling)
- Enums for business_type and currency_code dropdowns

---

### Task 1: Create Companies_NewModalController

**Files:**
- Create: `app/javascript/controllers/companies/new_modal_controller.js`

Reference files:
- `app/javascript/controllers/home/header/authentication_controller.js:28-42` (openModal pattern)
- `app/javascript/controllers/home/signup_modal_controller.js` (form pattern with manual fetch)

- [ ] **Step 1: Create the modal controller**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class Companies_NewModalController extends Controller {
  openModal(event) {
    if (event) {
      event.preventDefault()
    }
    openModal({
      html: `<div data-controller="${this.identifier}"></div>`
    })
  }

  closeModal(event) {
    if (event) {
      event.preventDefault()
    }
    closeModal()
  }

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async submit(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    const data = {
      company: {
        name: formData.get('company[name]'),
        business_type: formData.get('company[business_type]'),
        currency_code: formData.get('company[currency_code]'),
        phone_number: formData.get('company[phone_number]')
      }
    }

    try {
      const response = await fetch('/companies', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify(data)
      })

      const result = await response.json()

      if (response.ok) {
        this.closeModal()
        
        const company = result.company
        const dashboardUrl = `/companies/${company.id}/dashboards`
        
        toast(`
          Company "${company.name}" created! 
          <a href="${dashboardUrl}" class="ml-2 font-bold text-indigo-600 hover:underline">Go to Dashboard →</a>
        `, 'success')
        
        window.location.reload()
      } else {
        const errors = result.errors?.join(', ') || 'Failed to create company'
        toast(errors, 'warning')
      }
    } catch (error) {
      toast('An error occurred. Please try again.', 'error')
    }
  }

  modalHTML() {
    const businessTypes = [
      { value: 'retail', label: 'Retail' },
      { value: 'service', label: 'Service' },
      { value: 'hospitality', label: 'Hospitality' },
      { value: 'manufacturing', label: 'Manufacturing' },
      { value: 'other', label: 'Other' }
    ]

    const currencyCodes = [
      { value: 'usd', label: 'USD - US Dollar' },
      { value: 'eur', label: 'EUR - Euro' },
      { value: 'gbp', label: 'GBP - British Pound' },
      { value: 'vnd', label: 'VND - Vietnamese Dong' },
      { value: 'jpy', label: 'JPY - Japanese Yen' },
      { value: 'cad', label: 'CAD - Canadian Dollar' },
      { value: 'aud', label: 'AUD - Australian Dollar' }
    ]

    const formFields = `
      <div class="space-y-4">
        <div>
          <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left">
            Company Name *
          </label>
          <input
            class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
            name="company[name]" placeholder="My Company" type="text" required />
        </div>
        <div>
          <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left">
            Business Type *
          </label>
          <select
            class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
            name="company[business_type]" required>
            <option value="">Select business type</option>
            ${businessTypes.map(bt => `<option value="${bt.value}">${bt.label}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left">
            Currency *
          </label>
          <select
            class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
            name="company[currency_code]" required>
            <option value="">Select currency</option>
            ${currencyCodes.map(c => `<option value="${c.value}">${c.label}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left">
            Phone (optional)
          </label>
          <input
            class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
            name="company[phone_number]" placeholder="+1 234 567 8900" type="text" />
        </div>
      </div>
      <div class="mt-6 flex justify-end gap-3">
        <button
          type="button"
          data-action="click->${this.identifier}#closeModal"
          class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg dark:text-slate-300 dark:hover:bg-slate-700">
          Cancel
        </button>
        <button
          type="submit"
          data-action="submit->${this.identifier}#submit"
          class="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-bold text-sm">
          Create Company
        </button>
      </div>
    `

    return `
      <div class="flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
        <div class="relative w-full max-w-[480px] rounded-xl bg-white p-6 shadow-2xl md:p-8 dark:bg-slate-800">
          <button
            data-action="click->${this.identifier}#closeModal"
            class="absolute right-4 top-4 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">
            <span class="material-symbols-outlined">close</span>
          </button>
          <div class="mb-6 text-center">
            <h3 class="mb-2 text-2xl font-bold text-slate-900 dark:text-white">Create New Company</h3>
            <p class="text-sm text-slate-600 dark:text-slate-400">Fill in details for your new company</p>
          </div>
          <form action="/companies" method="POST">
            ${formPostSecurityTags()}
            ${formFields}
          </form>
        </div>
      </div>
    `
  }
}
```

- [ ] **Step 2: Verify file was created**

Run: `ls -la app/javascript/controllers/companies/new_modal_controller.js`

Expected: File exists

- [ ] **Step 3: Test manually**

Navigate to home page, click "New Company" button, verify modal opens

---

### Task 2: Backend - Allow Additional Params

**Files:**
- Modify: `app/controllers/companies_controller.rb`

Current allowed: `:name, :business_type`  
Need to add: `:currency_code, :phone_number`

- [ ] **Step 1: Update permitted params**

Run: Edit `app/controllers/companies_controller.rb`

```ruby
def company_params
  params.require(:company).permit(:name, :business_type, :currency_code, :phone_number)
end
```

---

### Task 3: Test End-to-End

- [ ] **Step 1: Open home page**

Navigate to `/` (home page)

- [ ] **Step 2: Click New Company button**

Verify modal opens with form

- [ ] **Step 3: Fill form and submit**

Fill: name="Test Company", business_type="retail", currency_code="usd"

- [ ] **Step 4: Verify success**

- Modal closes
- Toast shows "Company Test Company created! Go to Dashboard →"
- Click toast link → navigates to `/companies/:id/dashboards`