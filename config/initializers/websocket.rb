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
  # Convention: key == value — the wire string is identical to the symbol key,
  # so only one string needs to be remembered/declared per event.
  EVENTS = {
    test: "test",
    top_up_completed: "top_up_completed",
    pos_payment_completed: "pos_payment_completed",
    notification_created: "notification_created",
    company_ticket_created: "company_ticket_created",
    company_ticket_commented: "company_ticket_commented",
    company_ticket_status_changed: "company_ticket_status_changed"
  }.freeze

  class << self
    # --- Channel Generator (Source of Truth) ---
    # Format: "<model_name>_<id>" e.g. "company_<uuid>", "user_<uuid>".
    def channel_name(model_name, id)
      return nil unless model_name && id
      "#{model_name.to_s.downcase}_#{id}"
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
    # window.WEBSOCKET.subscribe(window.WEBSOCKET.channelName("company", currentCompany().id), "test", (data) => {
    #   console.log(data)
    # })
    def test(model_name, id)
      publish_event(
        channel: WEBSOCKET.channel_name(model_name, id),
        event_key: :test,
        data: {
          project: "Skycom",
          project_type: "ERP"
        }
      )
    end
  end
end
