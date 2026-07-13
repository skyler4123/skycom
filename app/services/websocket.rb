# app/services/websocket.rb
class Websocket
  CLIENT = Cent::Client.new(
    api_key: "skycom_super_secret_api_key_2026",
    endpoint: "http://localhost:8000/api"
  )

  NOTARY = Cent::Notary.new(
    secret: "skycom_jwt_hmac_secret_token_key_2026"
  )

  class << self
    # Keeps your exact publishing interface
    def publish(channel:, data:)
      CLIENT.publish(channel: channel, data: data)
    end

    # Keeps your exact sub and channels interface
    def token(sub:, channels:)
      NOTARY.issue_connection_token(sub: sub, channels: channels)
    end
  end
end
