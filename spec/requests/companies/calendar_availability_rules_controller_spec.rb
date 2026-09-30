# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CalendarAvailabilityRulesController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:practitioner) { create(:calendar_practitioner, company: company) }
  let(:location) { create(:calendar_location, company: company) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: owner.email) }

  def payload(overrides = {})
    {
      calendar_availability_rule: {
        name: "Weekday hours",
        timezone: "UTC",
        days_of_week: [ 1, 2, 3, 4, 5 ],
        start_time: "09:00",
        end_time: "17:00"
      }.merge(overrides)
    }
  end

  describe "GET #index" do
    it "lists rules with their owner label" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)

      get company_calendar_availability_rules_path(company), as: :json

      expect(response).to have_http_status(:ok)
      rule = JSON.parse(response.body)["calendar_availability_rules"].first
      expect(rule["owner_label"]).to eq(practitioner.name)
      expect(rule["working"]).to be(true)
    end

    it "filters by practitioner" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)
      other = create(:calendar_practitioner, company: company)
      create(:calendar_availability_rule, company: company, calendar_practitioner: other)

      get company_calendar_availability_rules_path(company, practitioner_id: practitioner.id), as: :json

      expect(JSON.parse(response.body)["calendar_availability_rules"].size).to eq(1)
    end

    it "filters by location" do
      create(:calendar_availability_location_rule, company: company, calendar_location: location)

      get company_calendar_availability_rules_path(company, location_id: location.id), as: :json

      expect(JSON.parse(response.body)["calendar_availability_rules"].size).to eq(1)
    end

    it "separates blackouts from working hours" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)
      create(:calendar_availability_blackout, company: company, calendar_practitioner: practitioner)

      get company_calendar_availability_rules_path(company, blackout: "true"), as: :json

      rules = JSON.parse(response.body)["calendar_availability_rules"]
      expect(rules.size).to eq(1)
      expect(rules.first["is_unavailable"]).to be(true)
    end
  end

  describe "POST #create" do
    it "creates a practitioner rule" do
      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["calendar_availability_rule"]["start_time"]).to eq("09:00")
    end

    it "creates a location rule" do
      post company_calendar_availability_rules_path(company),
        params: payload(calendar_location_id: location.id), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "rejects a rule with no owner" do
      post company_calendar_availability_rules_path(company), params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("practitioner or a location")
    end

    it "rejects a rule owned by both a practitioner and a location" do
      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, calendar_location_id: location.id), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("not both")
    end

    it "rejects an overnight window" do
      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "22:00", end_time: "06:00"), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("overnight")
    end

    it "rejects a malformed time" do
      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "9am"), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("HH:MM")
    end

    it "rejects an overlapping window for the same practitioner and days" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner,
        days_of_week: [ 1, 2, 3, 4, 5 ], start_time: "09:00", end_time: "12:00")

      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "11:00", end_time: "15:00"), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("Overlaps")
    end

    it "allows a back-to-back window on the same day" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner,
        days_of_week: [ 1, 2, 3, 4, 5 ], start_time: "09:00", end_time: "12:00")

      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "12:00", end_time: "15:00"), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "allows the same window on disjoint days" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner,
        days_of_week: [ 1 ], start_time: "09:00", end_time: "17:00")

      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id, days_of_week: [ 2 ]), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "allows the same window for a different practitioner" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)
      other = create(:calendar_practitioner, company: company)

      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: other.id), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "does not treat a blackout as overlapping working hours" do
      create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)

      post company_calendar_availability_rules_path(company),
        params: payload(calendar_practitioner_id: practitioner.id,
                        start_time: "10:00", end_time: "11:00", is_unavailable: true), as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates a rule" do
      rule = create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)

      patch company_calendar_availability_rule_path(company, rule),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "08:00"), as: :json

      expect(response).to have_http_status(:ok)
      expect(rule.reload.start_time).to eq("08:00")
    end

    it "does not treat itself as an overlap" do
      rule = create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner,
        start_time: "09:00", end_time: "12:00")

      patch company_calendar_availability_rule_path(company, rule),
        params: payload(calendar_practitioner_id: practitioner.id, start_time: "10:00", end_time: "14:00"), as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE #destroy" do
    it "removes the rule" do
      rule = create(:calendar_availability_rule, company: company, calendar_practitioner: practitioner)

      delete company_calendar_availability_rule_path(company, rule), as: :json

      expect(response).to have_http_status(:ok)
      expect(CalendarAvailabilityRule.exists?(rule.id)).to be(false)
    end
  end

  describe "tenancy" do
    it "cannot read another company's rule" do
      foreign_company = create(:company)
      foreign = create(:calendar_availability_rule,
        company: foreign_company,
        calendar_practitioner: create(:calendar_practitioner, company: foreign_company))

      get company_calendar_availability_rule_path(company, foreign), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
