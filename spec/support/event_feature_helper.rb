# frozen_string_literal: true

# Shared localStorage seeding for Event-domain feature specs (events,
# event_configs, calendars). Mirrors the suppliers pattern: clear storage,
# serialize associations with .reset, lock the client cache version so
# ClientCacheController.sync() cannot clobber the seed.
module EventFeatureHelper
  def seed_event_client_cache(company:, owner:, enums: {})
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => company.branches.reset.map { |b| JSON.parse(b.to_json) },
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: enums,
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  def event_enums_payload
    {
      event: {
        business_types: [
          { name: "Appointment", value: "appointment" },
          { name: "Procedure", value: "procedure" },
          { name: "Reservation", value: "reservation" },
          { name: "Banquet", value: "banquet" }
        ],
        workflow_statuses: [
          { name: "Pending", value: "pending" },
          { name: "Confirmed", value: "confirmed" },
          { name: "In Progress", value: "in_progress" },
          { name: "Completed", value: "completed" },
          { name: "Cancelled", value: "cancelled" }
        ]
      }
    }
  end
end

RSpec.configure do |config|
  config.include EventFeatureHelper, type: :feature
end
