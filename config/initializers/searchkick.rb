if Rails.application.credentials.dig(:opensearch_url)
  Searchkick.client = OpenSearch::Client.new(
    url: Rails.application.credentials.dig(:opensearch_url),
    transport_options: {
      request: { timeout: 5 }
    }
  )
else
  Searchkick.client = OpenSearch::Client.new(
    host: Rails.application.credentials.dig(:opensearch_host) || "localhost",
    port: Rails.application.credentials.dig(:opensearch_port) || 9200,
    user: Rails.application.credentials.dig(:opensearch_user),
    password: Rails.application.credentials.dig(:opensearch_password),
    transport_options: {
      request: { timeout: 5 }
    }
  )
end
