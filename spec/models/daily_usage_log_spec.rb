# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyUsageLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to belong_to(:billing_resource) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:log_date) }
  end

  describe "uniqueness on [company_id, billing_resource_id, log_date]" do
    let(:company)  { create(:company) }
    let(:resource) { create(:billing_resource, :volumetric, name: "test_unique_resource") }

    it "allows different resources for the same company+date" do
      create(:daily_usage_log, company: company, billing_resource: resource, log_date: Date.current)
      other = create(:billing_resource, :volumetric, name: "other_resource")
      expect { create(:daily_usage_log, company: company, billing_resource: other, log_date: Date.current) }
        .not_to raise_error
    end

    it "allows same resource+date for different companies" do
      create(:daily_usage_log, company: company, billing_resource: resource, log_date: Date.current)
      other_company = create(:company)
      expect { create(:daily_usage_log, company: other_company, billing_resource: resource, log_date: Date.current) }
        .not_to raise_error
    end
  end
end
