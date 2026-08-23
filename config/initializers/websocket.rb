# config/initializers/websocket.rb

# We define it as a clean, structured Module/Class bound directly to the WEBSOCKET constant
class WEBSOCKET
  CLIENT = Cent::Client.new(
    api_key: ENV["CENTRIFUGO_API_KEY"] || Rails.application.credentials.centrifugo_api_key || "skycom_super_secret_api_key_2026",
    endpoint: ENV["CENTRIFUGO_ENDPOINT"] || Rails.application.credentials.centrifugo_endpoint || "http://localhost:8000/api"
  )

  NOTARY = Cent::Notary.new(
    secret: ENV["CENTRIFUGO_TOKEN_HMAC_SECRET_KEY"] || Rails.application.credentials.centrifugo_token_hmac_secret_key || "skycom_jwt_hmac_secret_token_key_2026"
  )

  # --- Unified Event Types (Registry) ---
  EVENTS = {
    test: "test",
    top_up_completed: "top_up.completed"
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

    # --- Connectivity Check ---
    def ping
      response = CLIENT.info
      response.dig("result", "nodes", 0, "version").present?
    rescue => e
      false
    end

    # --- Core Connection Token Handshake ---
    def token(sub:, channels:)
      NOTARY.issue_connection_token(sub: sub, channels: Array(channels))
    end

    # Test WEBSOCKET, make sure use the valid and same channel. FE must run this code to subscribe
    # window.WEBSOCKET.subscribe(window.WEBSOCKET.companyChannel(currentCompany().id), "test", (data) => {
    #   console.log(data)
    # })
    def test(channel)
      publish_event(
        channel: WEBSOCKET.company_channel(channel),
        event_key: :test,
        data: {
          project: "Skycom",
          project_type: "ERP"
        }
      )
    end
  end
end
