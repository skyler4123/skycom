# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "json"

MOCK_API_PING_URL = ENV["MOCK_API_PING_URL"] || Rails.application.credentials.mock_api_ping_url || "http://localhost:4000/api/v1/ping"

RSpec.describe "Mock API Server Connection", type: :request do
  let(:uri) { URI(MOCK_API_PING_URL) }

  it "responds to ping endpoint" do
    response = Net::HTTP.get_response(uri)
    expect(response).to be_a(Net::HTTPOK)
    expect(response.code.to_i).to eq(200)
  end

  it "returns expected JSON body" do
    response = Net::HTTP.get_response(uri)
    body = JSON.parse(response.body)

    expect(body).to include(
      "status" => "online",
      "message" => "🚀 Skycom Auto-Redirect Multi-Bank Sandbox is active!"
    )
  end
end
