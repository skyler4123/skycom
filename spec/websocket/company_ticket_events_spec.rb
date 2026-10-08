require "rails_helper"

RSpec.describe "CompanyTicket websocket events" do
  it "registers ticket events with key == value" do
    expect(WEBSOCKET::EVENTS[:company_ticket_created]).to eq("company_ticket_created")
    expect(WEBSOCKET::EVENTS[:company_ticket_commented]).to eq("company_ticket_commented")
    expect(WEBSOCKET::EVENTS[:company_ticket_status_changed]).to eq("company_ticket_status_changed")
  end
end
