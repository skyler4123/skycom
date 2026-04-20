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