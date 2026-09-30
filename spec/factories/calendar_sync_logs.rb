# spec/factories/calendar_sync_logs.rb
FactoryBot.define do
  factory :calendar_sync_log do
    company { association :company }
    calendar_sync_connection { association :calendar_sync_connection, company: company }

    provider { "calcom" }
    direction { :push }
    status { :success }
    entity_type { "CalendarEvent" }
    entity_id { SecureRandom.uuid }
    external_id { "ext-#{SecureRandom.hex(4)}" }
    request_payload { {} }
    response_payload { {} }
    duration_ms { 120 }
  end

  factory :failed_calendar_sync_log, parent: :calendar_sync_log do
    status { :error }
    error_message { "Provider returned 503" }
  end
end
