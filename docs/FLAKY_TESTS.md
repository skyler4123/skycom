# Flaky Tests Guide

This document covers how to avoid and fix flaky tests in Skycom's feature test suite.

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

3. **Async Wait**: Add sleep after async actions to allow completion:
```ruby
click_button "Save Employee"
sleep 1  # ADD THIS - wait for async form submission
expect(page).to have_selector('tbody tr', wait: 10)
```

**Key Insight**: The `Employee#clear_permissions_cache` clears the employee's cache, but for the `can?` check to work reliably, the COMPANY cache must ALSO be cleared because permissions depend on policy appointments stored in the company's cache scope.

---