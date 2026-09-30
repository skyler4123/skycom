# spec/factories/calendar_sync_connections.rb
FactoryBot.define do
  factory :calendar_sync_connection do
    company { association :company }

    provider { "calcom" }
    status { :disconnected }
    external_organization_id { nil }
    base_url { "http://calcom:3000" }
    credentials { { api_key: "test-key" } }
  end

  factory :connected_calendar_sync_connection, parent: :calendar_sync_connection do
    status { :connected }
    external_organization_id { "org-123" }
  end
end
