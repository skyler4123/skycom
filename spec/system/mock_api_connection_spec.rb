# frozen_string_literal: true

require "rails_helper"

MOCK_API_PING_URL = ENV["MOCK_API_PING_URL"] || Rails.application.credentials.mock_api_ping_url || "http://localhost:4000/api/v1/ping"

RSpec.describe "Mock API Server Connection", type: :request do
  let(:connection) do
    Faraday.new(url: MOCK_API_PING_URL) do |f|
      f.request :json
      f.response :json
      f.options.timeout = 5
    end
  end

  it "responds to ping endpoint" do
    response = connection.get
    expect(response.success?).to be true
    expect(response.status).to eq(200)
  end

  it "returns expected JSON body" do
    response = connection.get
    body = JSON.parse(response.body)

    expect(body).to include(
      "status" => "online",
      "message" => "🚀 Skycom Auto-Redirect Multi-Bank Sandbox is active!"
    )
  end
end
