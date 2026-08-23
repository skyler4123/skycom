# Flaky Tests Guide

This document covers how to avoid and fix flaky tests in Skycom's feature test suite.

## Critical Rule: Never Use `sleep` in Feature Tests

**DO NOT use `sleep` in feature tests.** It is bad practice that:
- Creates flaky, timing-dependent tests
- Slows down test suite unnecessarily
- Hides real race condition issues that should be fixed properly

**Always use Capybara's built-in waiting mechanisms instead:**
```ruby
# Good - Capybara waits for element to appear
expect(page).to have_selector('tbody tr', wait: 10)

# Bad - hardcoded sleep (NEVER do this)
sleep 2
```

---

## Common Causes of Flaky Tests

### 1. Race Conditions

**Problem**: Code depends on async data that isn't ready when the test runs.

**Example**: `ClientCacheController` loads data from an API, but tests don't wait for it to complete.

**Solution**:
```javascript
// In client_cache_controller.js - Check if cache exists, not just version
const hasLocalCache = !!localStorage.getItem('client_cache_data')
if (!hasLocalCache || (serverVersion && serverVersion !== localVersion)) {
  await this.refreshCache(serverVersion || 'initial')
}
```

### 2. Factory Not Passing Attributes

**Problem**: Factory trait values aren't forwarded to the service that creates records.

**Example**: Employee factory didn't pass `business_type` to `Seed::EmployeeService`.

**Solution**:
```ruby
# In spec/factories/employees.rb
initialize_with do
  Seed::EmployeeService.create(
    company: company,
    business_type: business_type  # Forward the attribute
  )
end
```

### 3. Confirm Dialogs Blocking

**Problem**: `form_controller.js` has a default confirm dialog that blocks in headless browsers.

**Solution**: Use `click_button` which triggers native form submit:
```ruby
click_button 'Save Employee'  # Better than find(...).click
```

### 4. Test Expectations vs Reality

**Problem**: Test expects a specific URL pattern but actual behavior differs slightly.

**Solution**: Adjust expectation to match actual behavior:
```ruby
# Before (flaky)
expect(page).not_to have_current_path(/department_id=#{department.id}/)

# After (stable)
expect(page).to have_current_path(/department_id=/)
```

---

## Best Practices for Feature Tests

### Use Capybara Helpers

| Use This | Instead of |
|---------|----------|
| `fill_in 'field', with: 'value'` | `find('input').set('value')` |
| `select 'Option', from: 'field'` | `find('select').select('Option')` |
| `click_button 'Save'` | `find('button').click` |
| `have_content('text')` | DOM assertions |

### Wait for Specific Elements

```ruby
# Good - waits for data to appear
expect(page).to have_selector('tbody tr', wait: 10)

# Bad - relies on timing
sleep 2
```

### Verify Database, Not Just UI

```ruby
# Good - verifies actual data persistence
expect(Employee.find_by(name: "New Employee")).to be_present

# Bad - only checks UI
expect(page).to have_content("success")
```

### Keep Tests Independent

Each test should create its own data using `let!` or within the test:
```ruby
let!(:employee) { create(:employee, company: company) }
```

### Use Reliable Selectors

```ruby
# Good - button text is stable
click_button 'Save Employee'

# Flaky - data-action can change
find('[data-action*="openNewModal"]').click
```

### Scope Searches to Parent Element

When interacting with one of multiple similar elements (like editable fields in a modal), scope subsequent searches to the specific element:

```ruby
# BAD: Global search finds ALL matching elements
editable_field = find('[data-controller="editable"]', match: :first)
find('.editable-input').fill_in(with: 'value')  # Ambiguous!

# GOOD: Scope to the specific element
editable_field = find('[data-controller="editable"]', match: :first)
editable_field.find('.editable-input').fill_in(with: 'value')
```

---

## Debugging Flaky Tests

1. **Run the test multiple times**:
   ```bash
   bundle exec rspec spec/features/...:52 --format documentation
   ```

2. **Check for race conditions**:
   - Look for async operations (API calls, cache loads, Turbo navigations)
   - Add explicit waits for elements

3. **Verify test isolation**:
   - Ensure each test creates its own data
   - Check for shared state between tests

---

## Retry Configuration

See `spec/retry_helper.rb`:
```ruby
config.default_retry_count = 1  # Currently minimal retries

config.around :each, :js do |ex|
  ex.run_with_retry retry: 1
end
```

Use retries sparingly - they mask real issues.

---

### 5. Permissions Cache Test Isolation

**Problem**: When tests use permission-based authorization (ABAC `can?` checks), clearing the permissions cache is critical for test isolation. Tests can fail with "permission denied" when run individually vs. as part of a full suite due to stale cache pollution.

**Example**: `permissions_spec.rb` test fails when run alone but passes in suite because earlier tests modified the company permissions cache.

**Root Causes**:
1. **Cache not cleared in setup**: Some employee `let!` blocks forgot to call `company.clear_permissions_cache`
2. **Single vs. full suite**: Running alone uses fresh cache; running after other tests uses polluted cache
3. **Timing**: Test checks database before async form submission completes

**Solution** (1 > 2 > 3 fixes):

1. **Setup**: Clear cache for ALL employees with role assignments:
```ruby
let!(:creator_employee) do
  create(:employee, company: company, branch: branch, user: creator_user, roles: [ creator_role ]).tap do
    company.clear_permissions_cache  # ADD THIS
  end
end
```

2. **Test**: Clear both employee AND company cache before use:
```ruby
scenario "creator can create new employee" do
  creator_employee.clear_permissions_cache
  company.clear_permissions_cache   # ADD THIS
  creator_employee.reload         # ADD THIS

  sign_in(creator_user)
  # ...
end
```

3. **Async Wait**: Use Capybara's built-in wait instead of sleep:
```ruby
click_button "Save Employee"
expect(page).to have_selector('tbody tr', wait: 10)  # Capybara waits for DOM update
```

**Key Insight**: The `Employee#clear_permissions_cache` clears the employee's cache, but for the `can?` check to work reliably, the COMPANY cache must ALSO be cleared because permissions depend on policy appointments stored in the company's cache scope.

---

### 6. Client Cache Enum Pollution (localStorage)

**Problem**: Tests fail with `Capybara::ElementNotFound: Unable to find option "Full Time"` when run as part of the full suite, but pass in isolation. The `<select>` renders with zero `<option>` elements.

**Root Cause**: The form renders `<option>` elements from `Enums()?.resource?.business_types`, which reads the client cache (`localStorage`). `seed_client_cache` seeds this data, but `ClientCacheController.sync()` overwrites localStorage on the next page load when the cookie version doesn't match the seeded version. Since `sync()` is async and `contentHTML()` renders synchronously during `connect()`, the controller reads from localStorage before the server response arrives — but in full-suite runs, cross-test state (stale cookies, other test data) can cause the sync to complete before the controller's `connect()`, overwriting the seeded enums.

**Symptoms**:
- `select 'Full Time', from: 'employee[business_type]'` → `"Unable to find option "Full Time"`
- `find('option', text: 'Full Time', wait: 5).select_option` → times out
- Passes in isolation (`bundle exec rspec spec/...:LINE`), fails in `spec/features/` full suite
- The `select` element exists in the DOM but is empty

**Fix 1 — Controller Fallback (always do this)**:

Every new/edit page controller that renders `<select>` from `Enums()` must include static fallback arrays:

```javascript
// app/javascript/controllers/companies/{resource}/new_controller.js
const typeOptions = (Enums()?.resource?.business_types || [
  { name: "Full Time", value: "full_time" },
  { name: "Part Time", value: "part_time" },
  // ...all possible types EXCEPT "owner"...
]).map(t => `<option value="${t.value}">${t.name}</option>`).join('')
```

This ensures dropdowns always have options, regardless of client cache state.

**Fix 2 — Test-Level (for form-submission tests)**:

When testing form submissions that depend on enum-based `<select>` elements, bypass the `select` helper entirely. Set the value via JavaScript after confirming the `<input[name]>` is present:

```ruby
# Instead of:
select 'Full Time', from: 'employee[business_type]'

# Use:
page.execute_script("document.querySelector('select[name=\"employee[business_type]\"]').value = 'full_time'")
```

This works only when the controller fallback (Fix 1) is in place — the browser rejects setting `.value` to a string that doesn't match any existing `<option>` element.

**Prevention Checklist**:
- When adding a new page controller with enum-backed `<select>`, ALWAYS include fallback arrays with every possible enum value.
- When writing feature tests that submit forms, use `page.execute_script` for enum selects rather than Capybara's `select`.
- The `seed_client_cache` helper is useful but insufficient alone — always pair it with controller-side fallbacks.
- Search the codebase for `Enums()?.` calls in page controllers to audit whether fallbacks are missing.

---

### 7. Shell-First `contentTarget` Race Condition

**Problem**: Page controllers that call `this.renderContent()` in `connect()` after an async fetch fail silently — the page renders as a bare layout shell with no content, but no error is visible. The failure appears flaky because it depends on timing between `renderLayout()` (from the parent `LayoutController`) and the child controller's fetch completion.

**Root Cause**: In the Shell-First architecture, `LayoutController.connect()` uses a `poll()` to wait for `currentCompany()` before calling `renderLayout()`. Only `renderLayout()` creates the `contentTarget` in the DOM. When a child controller calls `this.renderContent()` after its async fetch, `renderLayout()` may not have run yet. The guard `if (!this.hasContentTarget) return;` in `renderContent()` silently exits — no content, no error.

**Timeline of the race**:
```
super.connect()
  └─ poll() waits for currentCompany()     ← async, may not fire immediately
      └─ renderLayout()                    ← creates contentTarget in DOM

child.fetchJson(...)                        ← async, may complete before poll fires
  └─ this.renderContent()
      └─ hasContentTarget? → false         ← renderLayout hasn't run yet
      └─ return                            ← silently exits, page stays empty
```

**Fix — Always use `poll()` when calling `renderContent()` in `connect()`**:

Every page controller's `connect()` that fetches data and renders must wrap `renderContent()` in a `poll()` that waits for `hasContentTarget`:

```javascript
async connect() {
  super.connect()

  // ... fetch data ...

  poll(() => {
    if (this.hasContentTarget) {
      this.renderContent()
      return true
    }
    return false
  })
}
```

This is **required** for all controllers that extend `Companies_LayoutController`. Without it, the page will randomly render as an empty layout shell.

**Checklist for new page controllers**:
- Does it extend `Companies_LayoutController`?
- Does it call `this.renderContent()` in `connect()`?
- If yes, wrap it in `poll(() => { if (this.hasContentTarget) { ...; return true } })`

---

### 8. Stale DOM / Navigation Race After Form Submit (PATCH Redirect)

**Problem**: `spec/features/companies/attendance_policies/edit_spec.rb:43` fails intermittently with Selenium `UnknownError: Node with given id does not belong to the document` on `have_content` right after `click_button "Save Changes"`.

**Stack trace excerpt**:
```
Selenium::WebDriver::Error::UnknownError:
  unknown error: unhandled inspector error: {"code":-32000,"message":"Node with given id does not belong to the document"}
    # capybara/selenium/node.rb:187:in `visible?'
    # capybara/node/element.rb:306:in `visible?'
    # capybara/queries/selector_query.rb:572:in `matches_visibility_filters?'
```

**Root Cause**: The edit page uses `Helpers.form()` with `data-turbo="false"` → `PATCH` → `302 redirect` → show page. `click_button` triggers a full-page navigation that detaches the old DOM. If the next assertion is `have_content` (which queries `visible?` on the old document), Selenium holds a stale node handle that no longer belongs to the new document. Capybara's retry does not help because the error is `UnknownError`, not `StaleElementReferenceError`. The race is timing-dependent: if navigation is slow, `have_content` may still query the old DOM and throw.

The failure is **order-dependent**: checking `have_content` before `have_current_path` queries content while the old DOM is still attached but mid-teardown.

**Timeline**:
```
click_button "Save Changes"  →  browser starts navigation (old DOM detaches)
expect(page).to have_content("11.0")  ← queries old DOM → stale node → UnknownError
expect(page).to have_current_path(...)  ← never reached
```

**Fix — Always assert navigation first**:

Swap order so Capybara waits for the new document before querying content:

```ruby
# ❌ Flaky — content queried on old DOM
click_button "Save Changes"
expect(page).to have_content("11.0", wait: 10)
expect(page).to have_current_path(company_attendance_policy_path(company, attendance_policy), wait: 10)

# ✅ Stable — wait for new document, then query content
click_button "Save Changes"
expect(page).to have_current_path(company_attendance_policy_path(company, attendance_policy), wait: 10)
expect(page).to have_content("11.0", wait: 10)  # now queries show page after Stimulus fetch
```

`have_current_path` with `wait: 10` polls `window.location` until the redirect completes. Only then does `have_content` query the new show page (which itself async-fetches via `fetchJson` + `poll()` → `renderContent()`).

**Why this works for all Shell-First edit flows**:
- Edit controllers (`app/javascript/controllers/companies/*/edit_controller.js`) submit via standard HTML `form` (`data-turbo="false"`), not `fetchJson`. The server does `redirect_to company_*_path`.
- Show controllers load data via `fetchJson(...json)` + `poll(() => hasContentTarget)`. Content appears *after* navigation, so asserting `have_current_path` first gates the content check until the new Stimulus controller has mounted.

**Prevention Checklist for every edit/update feature spec**:
- After `click_button "Save Changes"` / `click_button "Update"`, the **very next** expectation must be `have_current_path` (the redirect target) with `wait: 10`.
- Only then assert `have_content` / `have_selector` for the updated value.
- Never assert content on the show page before asserting the URL — it re-introduces the stale-DOM race.
- Same rule applies to `create` flows (`have_current_path(new → show)`).

---

### 9. Faker + Uniqueness Collision (Deterministic Fixtures vs Factory)

**Problem**: `spec/features/companies/products/index_spec.rb:315` fails intermittently with:

```
ActiveRecord::RecordInvalid:
  Validation failed: Name has already been taken
  # ./spec/features/companies/products/index_spec.rb:223:in `block (4 levels) in <top (required)>'
  #   product.save!
```

The failure occurs in `let!` setup, before any `visit` — the feature test never reaches the browser.

**Root Cause**: Two sources of product names collide within the same `company_id` scope (`validates :name, uniqueness: { scope: :company_id }` at `app/models/product.rb:58`):

| Source | How name is generated | Example |
|--------|----------------------|---------|
| `let!(:product)` / `let!(:product2)` (top-level) | `create(:product)` → `Seed::ProductService.new` → `Faker::Commerce.product_name` (random) | `"Gorgeous Steel Plate"` |
| `let!(:products_cosmetics)` (dynamic-table block) | Deterministic array `["Gorgeous Steel Plate", "Practical Wool Shoes"]` at `spec/features/companies/products/index_spec.rb:189` | `"Gorgeous Steel Plate"` |

`Faker::Commerce.product_name` has a small pool (≈ dozens of distinct names). Probability that one of the two random products equals one of the 4 deterministic names is ~8% per example → flaky across the 1747-example suite. The `spec/factories/products.rb` `initialize_with` block does not prevent collision; overriding `name:` via `create(:product, name: "...")` does overwrite the Faker value *before save*, but the top-level lets did not pass an explicit `name`, so they kept the Faker value and collided.

**Timeline of the failing example** (`"integer property displays with numeric value"`):
```
let!(:product)  → Faker picks "Gorgeous Steel Plate" → saved as product.name
let!(:products_cosmetics) → tries to save "Gorgeous Steel Plate" again in same company
  → uniqueness validation fires → RecordInvalid → example fails in setup
```

**Fix — Give random fixtures unique, non-Faker names**:

Use `SecureRandom.hex` so the random products can never collide with the deterministic list:

```ruby
# spec/features/companies/products/index_spec.rb
let!(:product) do
  create(:product,
    company: company,
    name: "Base Physical Product #{SecureRandom.hex(4)}",  # unique, not in Faker pool
    business_type: "physical"
  )
end

let!(:product2) do
  create(:product,
    company: company,
    name: "Base Digital Product #{SecureRandom.hex(4)}",
    business_type: "digital",
    workflow_status: "pending"
  )
end
```

`create(:product, name: "...")` works because FactoryBot applies the override *after* `initialize_with` (the Faker name is overwritten before `save!`).

**Alternative fixes** (if you need deterministic names elsewhere):
- Append `SecureRandom.hex` to deterministic fixtures too: `"Gorgeous Steel Plate #{SecureRandom.hex(2)}"`
- Or use a sequence: `sequence(:name) { |n| "Product #{n} #{Faker::Commerce.product_name}" }` in the factory
- Or scope the deterministic list to `SecureRandom`-prefixed names to guarantee uniqueness

**Prevention Checklist**:
- Any spec that creates **two or more** products in the same `company` must ensure names are unique *within that company scope*. Check `validates :name, uniqueness: { scope: :company_id }` in the model before using `Faker`.
- If a `describe` block defines deterministic fixtures (like `products_cosmetics`), ensure all other `let!(:product)` in that file use explicit `name: "Unique ... #{SecureRandom.hex}"`, not bare `create(:product)`.
- Do not trust `Faker` for uniqueness when the model enforces `uniqueness` scoped to `company_id`. Always pass an explicit unique name when multiple records share a company in one example.
- Search for similar risk: `grep -rn 'create(:product' spec/features` and verify each file that mixes `Faker` products with hardcoded names.

---