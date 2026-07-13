# config/initializers/centrifugo.rb

# Using the correct Cent::Client class matching gem version 4.0+
WEBSOCKET = Cent::Client.new(
  api_key: "skycom_super_secret_api_key_2026",
  endpoint: "http://localhost:8000/api"
)

# Initialize the token generator for your security endpoints using the correct Cent::Notary class
CENTRIFUGO_NOTARY = Cent::Notary.new(
  secret: "skycom_jwt_hmac_secret_token_key_2026"
)
