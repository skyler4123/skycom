# frozen_string_literal: true

require "rails_helper"

RSpec.describe "init seeds the default Analytic" do
  around do |example|
    Company.skip_init = false
    example.run
    Company.skip_init = true
  end

  shared_examples "an analytic init" do |business_type|
    let(:company) { create(:company, business_type: business_type) }

    it "creates one active analytic with every block enabled" do
      analytic = company.analytics.first

      expect(analytic).to be_present
      expect(analytic.workflow_status).to eq("active")
      expect(analytic.blocks).to eq(Analytic::BLOCKS)
    end
  end

  describe "retail init" do
    include_examples "an analytic init", :retail
  end

  describe "hospital init" do
    include_examples "an analytic init", :hospital
  end

  describe "hotel init" do
    include_examples "an analytic init", :hotel
  end
end
