# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EventsController", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "events" }
    let(:index_class) { Event }
    let(:json_key) { "events" }
    let(:base_json_path) { "/companies/#{company.id}/events.json" }
    let(:record) { ->(company:, category:, **attrs) { create(:event, company: company, category: category, **attrs) } }
  end

  describe "JSON create/update" do
    let(:company) { create(:company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

    before { get sign_in_for_test_path(email: company.user.email) }

    it "creates an event and returns warnings" do
      post "/companies/#{company.id}/events",
        params: { event: { name: "Root Canal", category_id: category.id,
          start_at: 2.hours.from_now.iso8601, end_at: 3.hours.from_now.iso8601 } }, as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["event"]["name"]).to eq("Root Canal")
      expect(body["warnings"]).to eq([])
    end

    it "returns errors[] on validation failure" do
      post "/companies/#{company.id}/events",
        params: { event: { name: "", category_id: category.id } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "updates an event and returns warnings" do
      event = create(:event, company: company, category: category)

      patch "/companies/#{company.id}/events/#{event.id}",
        params: { event: { name: "Renamed" } }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["event"]["name"]).to eq("Renamed")
      expect(body).to have_key("warnings")
    end
  end
end
