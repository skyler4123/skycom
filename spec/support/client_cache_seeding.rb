# spec/support/client_cache_seeding.rb

# Shared client-cache seeding for feature specs. The enums payload comes from
# ClientCache::EnumsBuilder — the SAME builder as GET /client_cache — so spec
# seeding and production always agree (single source of truth, never hardcoded
# per-spec). The cookie version is locked to "forced" so
# ClientCacheController.sync() never runs and never overwrites the seeded
# payload mid-test (see docs/FLAKY_TESTS.md §6).
module ClientCacheSeeding
  def client_cache_payload(company:, user:, company_overrides: {}, enums: ClientCache::EnumsBuilder.build)
    company_data = JSON.parse(company.reload.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    ).merge(company_overrides)

    {
      user: JSON.parse(user.reload.to_json),
      companies: [ company_data ],
      enums: enums,
      employees: []
    }
  end

  def seed_full_client_cache(company:, user:)
    page.execute_script("localStorage.clear()")
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      client_cache_payload(company: company, user: user).to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end
end

RSpec.configure { |config| config.include ClientCacheSeeding }