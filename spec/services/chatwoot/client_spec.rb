# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chatwoot::Client do
  let(:connection) { instance_double(Faraday::Connection) }

  before { allow(described_class).to receive(:connection).and_return(connection) }

  describe ".request" do
    def stub_response(status, body: "{}")
      response = instance_double(Faraday::Response, status: status, body: body)
      allow(connection).to receive(:get).and_return(response)
    end

    it "builds the platform API path and parses a 200 JSON body" do
      stub_response(200, body: '{"id": 7, "name": "Grocery 1"}')

      expect(described_class.get("accounts")).to eq({ "id" => 7, "name" => "Grocery 1" })
    end

    it "sends the platform token header and returns {} for an empty 200 body (async DELETE)" do
      stub_response(200, body: "")
      allow(connection).to receive(:delete).and_return(instance_double(Faraday::Response, status: 200, body: ""))

      expect(described_class.delete("accounts/7")).to eq({})
    end

    it "raises NotFoundError on 404" do
      stub_response(404)

      expect { described_class.get("accounts/99") }.to raise_error(Chatwoot::NotFoundError)
    end

    it "raises UnauthorizedError on 401/403" do
      stub_response(403)

      expect { described_class.get("accounts/1") }.to raise_error(Chatwoot::UnauthorizedError)
    end

    it "raises the base error on other non-2xx" do
      stub_response(500)

      expect { described_class.get("accounts/1") }.to raise_error(Chatwoot::Error) { |e| expect(e).not_to be_a(Chatwoot::NotFoundError) }
    end

    it "wraps transport failures into ConnectionError" do
      allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new("refused"))

      expect { described_class.get("accounts/1") }.to raise_error(Chatwoot::ConnectionError, /refused/)
    end
  end

  describe "configuration readers" do
    around do |example|
      @original_env = ENV.to_h
      example.run
    ensure
      ENV.replace(@original_env)
    end

    it "falls back to the default base URL when nothing is configured" do
      allow(Rails.application.credentials).to receive(:dig).with(:chatwoot, :base_url).and_return(nil)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CHATWOOT_BASE_URL", anything).and_return(described_class::DEFAULT_BASE_URL)

      expect(described_class.base_url).to eq("http://localhost:3001")
    end

    it "prefers the environment base URL over the default" do
      allow(Rails.application.credentials).to receive(:dig).with(:chatwoot, :base_url).and_return(nil)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CHATWOOT_BASE_URL", anything).and_return("http://chatwoot-web:3000")

      expect(described_class.base_url).to eq("http://chatwoot-web:3000")
    end

    it "prefers credentials over the environment for the platform token" do
      allow(Rails.application.credentials).to receive(:dig).with(:chatwoot, :platform_token).and_return("cred_token")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CHATWOOT_PLATFORM_TOKEN").and_return("env_token")

      expect(described_class.platform_token).to eq("cred_token")
    end

    it "falls back to the environment platform token" do
      allow(Rails.application.credentials).to receive(:dig).with(:chatwoot, :platform_token).and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CHATWOOT_PLATFORM_TOKEN").and_return("env_token")

      expect(described_class.platform_token).to eq("env_token")
    end
  end
end
