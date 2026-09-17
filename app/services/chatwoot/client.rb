# frozen_string_literal: true

# Thin HTTP plumbing for the Chatwoot Platform API. Callers never touch
# Faraday directly — Chatwoot::BaseService is the domain surface and this
# client is its transport layer. See docs/CHATWOOT.md.
module Chatwoot
  class Client
    # Single-file constants (docs/CONSTANTS.md) — used only here.
    API_PREFIX = "/platform/api/v1"
    DEFAULT_BASE_URL = "http://localhost:3001"
    REQUEST_TIMEOUT_SECONDS = 5

    class << self
      def get(path)
        request(:get, path)
      end

      def post(path, body: {})
        request(:post, path, body: body)
      end

      def delete(path)
        request(:delete, path)
      end

      # Returns the parsed JSON body on 2xx ({} for empty bodies, e.g. the
      # async account DELETE). Raises typed errors otherwise:
      # 404 → NotFoundError, 401/403 → UnauthorizedError,
      # transport failure → ConnectionError, other non-2xx → Error.
      def request(method, path, body: nil)
        response = connection.public_send(method, "#{API_PREFIX}/#{path}") do |req|
          req.headers["Content-Type"] = "application/json" if body
          req.body = body.to_json if body
        end
        return parse_body(response.body) if response.status.between?(200, 299)
        raise NotFoundError, status_message(method, path, response) if response.status == 404
        raise UnauthorizedError, status_message(method, path, response) if [ 401, 403 ].include?(response.status)

        raise Error, status_message(method, path, response)
      rescue Faraday::Error => e
        raise ConnectionError, "Chatwoot #{method.upcase} #{path} failed: #{e.class} — #{e.message}"
      end

      def base_url
        Rails.application.credentials.dig(:chatwoot, :base_url) || ENV.fetch("CHATWOOT_BASE_URL", DEFAULT_BASE_URL)
      end

      def platform_token
        Rails.application.credentials.dig(:chatwoot, :platform_token) || ENV["CHATWOOT_PLATFORM_TOKEN"]
      end

      private

      def connection
        @connection ||= Faraday.new(url: base_url) do |conn|
          conn.headers["api_access_token"] = platform_token
          conn.options.open_timeout = REQUEST_TIMEOUT_SECONDS
          conn.options.timeout = REQUEST_TIMEOUT_SECONDS
        end
      end

      def parse_body(raw)
        return {} if raw.to_s.strip.empty?

        JSON.parse(raw)
      end

      def status_message(method, path, response)
        description = parse_body(response.body)["description"]
        "Chatwoot #{method.upcase} #{path} failed (#{response.status})#{": #{description}" if description}"
      end
    end
  end
end
