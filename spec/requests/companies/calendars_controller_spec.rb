# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CalendarsController", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

  before { get sign_in_for_test_path(email: company.user.email) }

  it "returns events in the requested range as board items" do
    inside = create(:event, company: company, category: category,
      name: "Inside", start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
    create(:event, company: company, category: category,
      name: "Outside", start_at: 30.days.from_now, end_at: 30.days.from_now + 1.hour)

    get "/companies/#{company.id}/calendar.json",
      params: { start: 1.day.from_now.to_date.iso8601, end: 7.days.from_now.to_date.iso8601 }

    expect(response).to have_http_status(:ok)
    items = JSON.parse(response.body)["events"]
    expect(items.map { |i| i["title"] }).to contain_exactly("Inside")
    expect(items.first).to include("id", "start", "end", "backgroundColor", "allDay")
    expect(inside.reload).to be_present
  end

  it "scopes to the company" do
    other = create(:company)
    other_category = Seed::CategoryService.find_or_create_for(company: other, resource_name: "events")
    create(:event, company: other, category: other_category,
      name: "Foreign", start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)

    get "/companies/#{company.id}/calendar.json",
      params: { start: 1.day.from_now.to_date.iso8601, end: 7.days.from_now.to_date.iso8601 }

    expect(JSON.parse(response.body)["events"]).to eq([])
  end
end
