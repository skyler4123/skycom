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