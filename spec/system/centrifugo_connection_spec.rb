# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Centrifugo WebSocket Server Connection", type: :request do
  it "responds to ping" do
    result = WEBSOCKET.ping
    expect(result).to be true
  end
end
