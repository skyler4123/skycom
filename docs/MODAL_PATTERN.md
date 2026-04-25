# Skycom Modal Pattern

This document describes how to add modals using the Shell-First pattern. Modals are triggered from index controllers but rendered by dedicated modal controllers.

## Overview

The modal pattern consists of three parts:

1. **Index Controller** — Has action methods that trigger modals
2. **Modal Controller** — Renders the modal content (form, show view, etc.)
3. **openModal()** — Global helper that creates the SweetAlert2 modal

## Step 1: Add Action to Index Controller

In your index controller, add a method that calls `openModal()`:

```javascript
// app/javascript/controllers/companies/employees/index_controller.js

import Companies_Employees_NewModalController from "controllers/companies/employees/new_modal_controller";
import Companies_Employees_ShowModalController from "controllers/companies/employees/show_modal_controller";

export default class Companies_Employees_IndexController extends Companies_LayoutController {
  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Employees_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { employeeId } = event.params
    window.currentEmployee = findById(this.employees, employeeId)
    openModal({ html: `<div data-controller="${identifier(Companies_Employees_ShowModalController)}"></div>` })
  }
}
```

**Key patterns:**

| Pattern | Purpose |
|---------|---------|
| `openModal({ html: ... })` | Uses keyword `html` (not named parameter) |
| `<div data-controller="...">` | Empty div — no content inside |
| `data-controller` attribute | Points to target Stimulus controller |
| `identifier(ControllerClass)` | Generates Stimulus identifier string |

**Identifier format:**
- `Companies_Employees_NewModalController` → `companies--employees--new-modal`

## Step 2: Create Modal Controller

Create a new modal controller that extends `Controller`:

```javascript
// app/javascript/controllers/companies/employees/new_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Employee</h2>
        
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Full Name</label>
            <input type="text" name="employee[name]" required placeholder="e.g. John Doe"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg">
            Cancel
          </button>
          <button type="submit" 
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
            Save Employee
          </button>
        </div>
      </div>
    `

    return form({
      action: pathname(),
      method: "POST",
      dataAction: `submit->form#submit`,
      className: "p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl",
      html: fields
    })
  }
}
```

**Key patterns:**

| Pattern | Purpose |
|---------|---------|
| `extends Controller` | Not a layout controller — standalone |
| `connect()` lifecycle | Renders content when modal opens |
| `this.element.innerHTML = ...` | Injects HTML into the empty div |
| `this.modalHTML()` method | Returns the full modal UI |
| `form({ ... })` helper | Wraps fields in form with CSRF |

## Step 3: Show Modal (View-Only)

For viewing details (not creation):

```javascript
// app/javascript/controllers/companies/employees/show_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_ShowModalController extends Controller {
  employee = null

  connect() {
    this.employee = /** @type {any} */ (window.currentEmployee)
    
    if (this.employee) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const e = this.employee

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">
          
          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Employee Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <p class="text-lg font-semibold text-slate-900 dark:text-white">${e.name}</p>
            <p class="text-sm text-slate-500">${e.email}</p>
          </div>
          
        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    window.closeModal()
  }
}
```

## How openModal Works

The `openModal()` helper is defined in `ui_helpers.js:221`:

```javascript
export const openModal = ({ html = "Model!", customClass = {}, ...rest }) => {
  Swal.fire({
    showConfirmButton: false,
    showCloseButton: false,
    backdrop: true,
    target: document.querySelector('main'),
    ...rest,
    html: html,
    customClass: {
      container: '!bg-transparent',
      popup: '!p-0 !bg-transparent !w-fit',
      htmlContainer: '!p-0 !overflow-visible',
      ...customClass
    }
  });
}
```

**Important details:**

1. **Keyword `html`** — Must use the `html` keyword parameter, not named parameter
2. **Empty div requirement** — The HTML must contain exactly ONE element (a div) with no content
3. **`data-controller` attribute** — This tells Stimulus which controller to initialize
4. **SweetAlert2** — openModal is a wrapper around SweetAlert2, so it supports all SweetAlert options

## Button Hookup in contentHTML

In your index controller's `contentHTML()`, hook the button to the action:

```javascript
<button
  type="button"
  data-action="click->${this.identifier}#openNewModal"
  class="px-4 py-2 bg-blue-600 text-white rounded-lg">
  Add Employee
</button>
```

For table rows with params:

```javascript
<button
  data-action="click->${this.identifier}#openShowModal"
  data-${this.identifier}-employee-id-param="${employee.id}"
  class="p-2 text-slate-500 hover:text-blue-600">
  <span class="material-symbols-outlined text-[20px]">edit</span>
</button>
```

## Summary

| Step | File | Key Pattern |
|------|------|------------|
| 1. Trigger | `index_controller.js` | `openModal({ html: \`<div data-controller="${identifier(Controller)}"></div>\` })` |
| 2. Render | `*_modal_controller.js` | `this.element.innerHTML = this.modalHTML()` in `connect()` |
| 3. Hook button | `contentHTML()` | `data-action="click->${this.identifier}#openNewModal"` |

**Critical rules:**

1. The `html` parameter must use keyword syntax (not `html: value`)
2. The HTML must be exactly one empty `<div>` with `data-controller` attribute
3. Modal controller extends `Controller`, not a layout controller
4. Use `form()` helper for forms with proper CSRF and method spoofing