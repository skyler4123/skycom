Meilisearch::Rails.configuration = {
  meilisearch_url: ENV["MEILISEARCH_HOST"] || Rails.application.credentials.dig(:meilisearch_host) || "http://localhost:7700",
  meilisearch_api_key: ENV["MEILISEARCH_API_KEY"] || Rails.application.credentials.dig(:meilisearch_api_key) || "skycom_master_key_password_2026",
  # Indexes are env-scoped (e.g. Product_development / Product_test) so local rspec
  # ms_clear_index! hooks can never wipe dev data on the shared server (docs/MEILISEARCH.md §8).
  per_environment: true
}
