# Skycom Constants Convention

## Rule
All app-wide constant values **MUST** be defined in `config/initializers/constants.rb`.
Never hardcode values inline in models, controllers, jobs, services, or concerns.

## Why
- **Single source of truth** — change one place, not 7+
- **Eliminates duplication** — image limits, owner strings, cache TTLs were duplicated across up to 9 files
- **Inline hardcoding is prohibited**

## What Belongs Here

| Type | Examples |
|------|----------|
| Numeric limits/thresholds | `MAX_IMAGE_ATTACHMENTS`, `COMPANY_PROCESSING_BATCH_SIZE` |
| Time durations | `COOKIE_EXPIRY`, `EMAIL_VERIFICATION_TOKEN_EXPIRY` |
| Magic strings | `OWNER_BUSINESS_TYPE`, `OWNER_POLICY_RESOURCE` |
| File/upload constraints | `MAX_IMAGE_FILE_SIZE`, `ACCEPTABLE_IMAGE_TYPES` |
| Image variant dimensions | `IMAGE_FULL_DIMENSIONS`, `AVATAR_PROFILE_DIMENSIONS` |
| Cache TTLs | `PERMISSIONS_CACHE_EXPIRY`, `DEFAULT_CACHE_EXPIRY` |
| Billing defaults & pricing | `DEFAULT_FREE_TIER_ALLOWANCES`, `BILLING_US_PRICES` |
| Array configs | `ALLOWED_TABLE_ALIGNS`, `PROPERTY_MAPPING_SUPPORTED_KEYS` |
| Enum mappings | `TIMEZONES`, `CURRENCIE_CODES`, `LIFECYCLE_STATUS`, `WORKFLOW_STATUS` |

## What Stays Local

| Scope | Reason |
|-------|--------|
| Environment-specific infrastructure config (`database.yml`, `cache.yml`, `queue.yml`) | Per-environment, not app-wide |
| Migration/schema defaults | Historical snapshots, not runtime config |
| Seed/fixture data (brand names, facility names, test counts) | Test/fixture data, not configuration |
| Test configuration (`spec/retry_helper.rb`) | Testing scope only |
| Gem-specific settings in their own initializers | Belongs with the gem config |

## How to Add a New Constant

1. Open `config/initializers/constants.rb`
2. Add the constant in the appropriate section with a descriptive comment
3. Freeze arrays and hashes with `.freeze`
4. Replace all inline usages with the constant name
5. Run `bin/rubocop` to verify

## Examples

```ruby
# Good — defined in config/initializers/constants.rb, referenced everywhere
MAX_IMAGE_ATTACHMENTS = 3

# Bad — hardcoded inline (DO NOT DO THIS)
if image_attachments.length > 3
```

## Referencing in Code

Constants are available globally in all Ruby files — no require or import needed:

```ruby
# In models
validates :phone_number, length: { maximum: MAX_PHONE_NUMBER_LENGTH }

# In controllers
cookies.signed[:session_token] = { value: session.id, expires: COOKIE_EXPIRY }

# In jobs
Company.find_each(batch_size: COMPANY_PROCESSING_BATCH_SIZE)

# In services
CORE_FREE_FEATURES.each do |feature_name|
  ContractFeature.find_or_create_by!(name: feature_name)
end
```
