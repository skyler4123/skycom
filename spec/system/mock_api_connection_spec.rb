# frozen_string_literal: true

require "rails_helper"

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
    expect(response.body).to include(
      "status" => "online",
      "message" => "🚀 Skycom Auto-Redirect Multi-Bank Sandbox is active!"
    )
  end
end
