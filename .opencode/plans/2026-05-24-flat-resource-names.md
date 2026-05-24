# Resource Names Flat Array Implementation Plan

> **For agentic workers:** Use `superpowers:subagent-driven-development` to implement this plan task-by-task.

**Goal:** Simplify the Company resource names system by flattening `DEFAULT_RESOURCE_NAMES` from a business-type-keyed hash to a single combined array, and remove the parallel `RESOURCES` constant from `Seed::RetailService`.

**Architecture:** Two independent changes: (1) the model's constant changes structure (hash→array), which cascades to the callback that uses it and to `Seed::CompanyService` which had its own parallel hash; (2) the seed service's redundant `RESOURCES` constant is replaced with a reference to the company instance's `resource_names`.

**Tech Stack:** Ruby on Rails, ActiveRecord

---

### Task 1: Flatten `Company::DEFAULT_RESOURCE_NAMES`

**Files:**
- Modify: `app/models/company.rb:77-90`
- Modify: `app/services/seed/company_service.rb:2,32`

- [ ] **Step 1: Change `DEFAULT_RESOURCE_NAMES` from hash to flat array**

  In `app/models/company.rb`, replace lines 77-84:

  Current (hash with business_type keys):
  ```ruby
  DEFAULT_RESOURCE_NAMES = {
    retail:     %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Category PropertyMapping Brand Facility],
    restaurant: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Table Reservation],
    hotel:      %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Room Booking Guest],
    hospital:   %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Patient Appointment],
    education:  %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Course Student Exam],
    fitness:    %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Membership Booking]
  }.freeze
  ```

  New (flat array — unique union of all above values):
  ```ruby
  DEFAULT_RESOURCE_NAMES = %w[
    Product Order Customer Employee Branch Department
    PolicyAppointment Invoice Payment Service
    Category PropertyMapping Brand Facility
    Table Reservation Room Booking Guest
    Patient Appointment Course Student Exam
    Membership
  ].freeze
  ```

- [ ] **Step 2: Update `set_default_resource_names` callback**

  In `app/models/company.rb`, replace lines 88-90:

  Current:
  ```ruby
  def set_default_resource_names
    self.resource_names = DEFAULT_RESOURCE_NAMES[business_type.to_sym] || DEFAULT_RESOURCE_NAMES[:retail]
  end
  ```

  New (just assign the flat array directly):
  ```ruby
  def set_default_resource_names
    self.resource_names = DEFAULT_RESOURCE_NAMES
  end
  ```

- [ ] **Step 3: Update `Seed::CompanyService::RESOURCE_NAMES`**

  In `app/services/seed/company_service.rb`, remove the `RESOURCE_NAMES` hash (lines 2-9) entirely.

  Remove `resource_names:` from the parameter list in `self.new` (line 32).

  Remove `resource_names:` from the `Company.new(...)` call (line 56).

  This lets the Company's `before_validation` callback (`set_default_resource_names`) populate `resource_names` from the flat `DEFAULT_RESOURCE_NAMES`.

- [ ] **Step 4: Verify**

  Run: `bin/rails runner 'puts Company::DEFAULT_RESOURCE_NAMES.inspect'`
  Expected: prints the flat array, no errors.

  Run: `bin/rails runner 'c = Company.new(business_type: :retail); c.valid?; puts c.resource_names.inspect'`
  Expected: `resource_names` is populated from the flat array.

  Run: `bundle exec rspec` (full suite) to check nothing breaks.

- [ ] **Step 5: Commit**

  ```bash
  git add -A
  git commit -m "refactor: flatten Company::DEFAULT_RESOURCE_NAMES into single combined array"
  ```

---

### Task 2: Remove `Seed::RetailService::RESOURCES`

**Files:**
- Modify: `app/services/seed/retail_service.rb:355,847`

- [ ] **Step 1: Remove the `RESOURCES` constant**

  In `app/services/seed/retail_service.rb`, delete line 355:
  ```ruby
  RESOURCES = %w[Order Product Employee Customer PolicyAppointment Booking Service Category PropertyMapping TableConfig Brand Facility]
  ```

- [ ] **Step 2: Replace the reference with `@retail.resource_names`**

  In `app/services/seed/retail_service.rb`, line 847, change:
  ```ruby
  RESOURCES.each do |resource|
  ```
  to:
  ```ruby
  @retail.resource_names.each do |resource|
  ```

- [ ] **Step 3: Verify**

  Run: `bundle exec rspec` to verify full suite passes.

- [ ] **Step 4: Commit**

  ```bash
  git add -A
  git commit -m "refactor: remove Seed::RetailService::RESOURCES, use company.resource_names"
  ```
