# New Company Modal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "New Company" nav to home page that opens a modal with a form to create a new company, then redirects to the company's dashboard.

**Architecture:** Minimal company creation form (name + business_type) that triggers the existing `Company#setup_owner_records` callback to create owner role/policy/employee. Uses shell-first JSON pattern.

**Tech Stack:** Ruby on Rails, StimulusJS, TailwindCSS

---

## File Structure

```
app/controllers/companies_controller.rb         # NEW - root companies controller
app/javascript/controllers/companies/new_modal_controller.js  # NEW
app/views/home/index.html.erb                    # MODIFY - add nav link
config/initializers/constants.rb                 # MODIFY - add shop/fitness types
app/controllers/client_cache_controller.rb       # MODIFY - add company enums
```

---

### Task 1: Add Business Types to Constants

**Files:**
- Modify: `config/initializers/constants.rb:1-54`

- [ ] **Step 1: Add shop and fitness business types to constants**

```ruby
BUSINESS_TYPES = {
  # Group 1: General & Retail (0-999)
  retail: 0,
  service: 1,
  shop: 2,              # ADD
  fitness: 3,          # ADD

  # Group 2: Food & Accommodation (1000-1999)
  restaurant: 1000,
  hotel: 1001,

  # Group 3: Medical (2000-2999)
  hospital: 2000,
  dental: 2001,
  optical: 2002,
  clinic: 2003,

  # Group 4: Education (3000-3999)
  education: 3000,
  university: 3001,
  english_center: 3002
}
```

- [ ] **Step 2: Verify constants reload**

Run: `bin/rails runner "puts BUSINESS_TYPES.keys"`
Expected: Includes :shop and :fitness

- [ ] **Step 3: Commit**

```bash
git add config/initializers/constants.rb
git commit -m "feat: add shop and fitness business types"
```

---

### Task 2: Add Company Enums to Client Cache

**Files:**
- Modify: `app/controllers/client_cache_controller.rb:11-17`

- [ ] **Step 1: Add company business_types to enums**

```ruby
format.json do
  render json: {
    user: current_user.as_json,
    companies: current_user.accessible_companies.as_json(include: [ :branches, :departments, :roles ]),
    enums: {
      employee: {
        lifecycle_statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Employee.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      company: {  # ADD
        business_types: Company.business_types.keys.map { |t| { name: t.humanize, value: t } }
      }
    },
    employees: current_user.employees
  }
end
```

- [ ] **Step 2: Commit**

```bash
git add app/controllers/client_cache_controller.rb
git commit -m "feat: add company business_types to client cache enums"
```

---

### Task 3: Create Root Companies Controller

**Files:**
- Create: `app/controllers/companies_controller.rb`

- [ ] **Step 1: Write failing test**

Create `spec/requests/companies_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe CompaniesController, type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /companies" do
    it "creates a new company" do
      expect {
        post companies_path, params: {
          company: { name: "Test Company", business_type: :retail }
        }
      }.to change(Company, :count).by(1)
    end

    it "returns JSON with company id" do
      post companies_path, params: {
        company: { name: "Test Company", business_type: :retail }
      }
      expect(response.parsed_body).to have_key("company")
      expect(response.parsed_body["company"]).to have_key("id")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/requests/companies_spec.rb`
Expected: FAIL - CompaniesController not defined

- [ ] **Step 3: Write minimal implementation**

Create `app/controllers/companies_controller.rb`:
```ruby
class CompaniesController < ApplicationController
  before_action :authenticate_user!

  def create
    company = current_user.companies.build(company_params)

    if company.save
      render json: { company: company }, status: :created
    else
      render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :business_type)
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/requests/companies_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/companies_controller.rb spec/requests/companies_spec.rb
git commit -m "feat: add CompaniesController with create action"
```

---

### Task 4: Create New Company Modal Controller

**Files:**
- Create: `app/javascript/controllers/companies/new_modal_controller.js`

- [ ] **Step 1: Create the modal controller**

```javascript
import { Controller } from "@hotwired/stimulus"
import * as Helpers from "controllers/helpers"

export default class Companies_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const fields = `
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
            Company Name
          </label>
          <input
            type="text"
            name="company[name]"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Enter company name"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
            Business Type
          </label>
          <select
            name="company[business_type]"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">Select business type</option>
            ${this.businessTypeOptions()}
          </select>
        </div>
        <div class="flex justify-end gap-3 pt-4">
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
            ${Helpers.closeModalAction()}
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg"
          >
            Create Company
          </button>
        </div>
      </div>
    `

    return Helpers.form({
      action: Helpers.pathname(),
      method: "POST",
      className: "p-6 bg-white dark:bg-slate-900 rounded-2xl w-[480px] max-w-[90vw]",
      html: fields
    })
  }

  businessTypeOptions() {
    const types = Helpers.Enums().company?.business_types || []
    return types.map(t => 
      `<option value="${t.value}">${t.name}</option>`
    ).join('')
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/controllers/companies/new_modal_controller.js
git commit -m "feat: add Companies_NewModalController"
```

---

### Task 5: Update Home Page Navigation

**Files:**
- Modify: `app/views/home/index.html.erb:14-17`

- [ ] **Step 1: Add "New Company" nav link**

Replace existing nav section:
```erb
<nav class="flex flex-1 justify-around items-center px-4">
  <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
    href="/redirect/companies">My Companies
  </a>

  <button
    class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
    data-controller="companies--new-modal"
    data-action="click->companies--new-modal#openModal"
  >
    New Company
  </button>
</nav>
```

Wait - need to update the JS controller to handle the click. Let me update the controller to have an openModal method:

- [ ] **Step 2: Add openModal method to controller**

Update `app/javascript/controllers/companies/new_modal_controller.js`:
```javascript
export default class Companies_NewModalController extends Controller {
  openModal(event) {
    event.preventDefault()
    Helpers.openModal(this.modalHTML())
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add app/views/home/index.html.erb app/javascript/controllers/companies/new_modal_controller.js
git commit -m "feat: add New Company nav to home page"
```

---

### Task 6: Test End-to-End Flow

**Files:**
- Test: Manual verification

- [ ] **Step 1: Start dev server**

Run: `bin/dev`

- [ ] **Step 2: Navigate to home page**

Open: `http://localhost:3000`

- [ ] **Step 3: Click "New Company" nav**

Expected: Modal opens with form

- [ ] **Step 4: Fill form and submit**

- Enter company name: "Test Retail Shop"
- Select business type: "Retail"
- Click "Create Company"

Expected:
- Toast shows "Success"
- Redirect to `/companies/{id}/dashboard`
- Owner role/employee created automatically

- [ ] **Step 5: Verify company exists in database**

Run: `bundle exec rails c`
```ruby
Company.last.name  # => "Test Retail Shop"
Company.last.roles.first.name  # => "owner"
```

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "test: verify new company flow works end-to-end"
```

---

## Implementation Complete

The "New Company" feature is now implemented with:
- ✅ Business types (shop, fitness) added to constants
- ✅ Company enums exposed via client cache
- ✅ CompaniesController with create action
- ✅ Stimulus modal controller with form
- ✅ Home page navigation updated
- ✅ Owner records auto-created via callback