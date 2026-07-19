# config/initializers/websocket.rb

# We define it as a clean, structured Module/Class bound directly to the WEBSOCKET constant
class WEBSOCKET
  CLIENT = Cent::Client.new(
    api_key: "skycom_super_secret_api_key_2026",
    endpoint: "http://localhost:8000/api"
  )

  NOTARY = Cent::Notary.new(
    secret: "skycom_jwt_hmac_secret_token_key_2026"
  )

  # --- Unified Event Types (Registry) ---
  EVENTS = {
    test: "test",
    top_up_completed: "top_up.completed",
    invoice_paid:     "invoice.paid",
    balance_updated:  "balance.updated",
    alert_triggered:  "alert.triggered"
  }.freeze

  class << self
    # --- Channel Generators (Source of Truth) ---
    def company_channel(company_id)
      return nil unless company_id
      "#{company_id}"
    end

    def user_channel(user_id)
      return nil unless user_id
      "#{user_id}"
    end

    # --- Secure Publishing with Envelope Verification ---
    def publish_event(channel:, event_key:, data: {})
      event_name = EVENTS[event_key.to_sym]
      raise "Unregistered websocket event key: [#{event_key}]" unless event_name

      envelope = {
        event: event_name,
        id: data[:id], # Target resource UUID tracking
        payload: data.except(:id)
      }

      CLIENT.publish(channel: channel, data: envelope)
    end

    # --- Core Connection Token Handshake ---
    def token(sub:, channels:)
      NOTARY.issue_connection_token(sub: sub, channels: Array(channels))
    end
  end
end
