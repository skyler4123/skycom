Meilisearch::Rails.configuration = {
  meilisearch_url: ENV["MEILISEARCH_HOST"] || Rails.application.credentials.dig(:meilisearch_host) || "http://localhost:7700",
  meilisearch_api_key: ENV["MEILISEARCH_API_KEY"] || Rails.application.credentials.dig(:meilisearch_api_key) || "skycom_master_key_password_2026"
}
