# frozen_string_literal: true

require "rails_helper"

RSpec.describe "init seeds the default Dashboard" do
  around do |example|
    Company.skip_init = false
    example.run
    Company.skip_init = true
  end

  shared_examples "a dashboard init" do |business_type|
    let(:company) { create(:company, business_type: business_type) }

    it "creates one active dashboard with every block enabled" do
      dashboard = company.dashboards.first

      expect(dashboard).to be_present
      expect(dashboard.workflow_status).to eq("active")
      expect(dashboard.blocks).to eq(Dashboard::BLOCKS)
    end
  end

  describe "retail init" do
    include_examples "a dashboard init", :retail
  end

  describe "hospital init" do
    include_examples "a dashboard init", :hospital
  end

  describe "hotel init" do
    include_examples "a dashboard init", :hotel
  end
end
