# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ApplicationController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "set_past_due_warning" do
    before do
      # Ensure day is >= 15 so the day guard doesn't interfere
      allow(Time).to receive(:current).and_return(Time.new(2026, 6, 20, 10, 0, 0))
      company.update_columns(lifecycle_status: Company.lifecycle_statuses[:past_due],
                              suspension_at: 1.week.from_now)
    end

    it "skips the past_due warning when hide_billing_alerts is true" do
      company.update_columns(hide_billing_alerts: true)
      company.reload
      get "/companies/#{company.id}/dashboards"
      expect(flash[:alert]).to be_blank
    end

    it "shows the past_due warning when hide_billing_alerts is false" do
      company.update_columns(hide_billing_alerts: false)
      company.reload
      get "/companies/#{company.id}/dashboards"
      expect(flash[:alert]).to be_present
    end
  end
end
