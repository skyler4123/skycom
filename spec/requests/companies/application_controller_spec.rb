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

  describe "check_accessable" do
    it "redirects to billing page when lifecycle_status is suspended (not accessible)" do
      company.update!(lifecycle_status: :suspended)
      get "/companies/#{company.id}/dashboards"
      expect(response).to redirect_to(company_billing_path(company))
    end

    it "allows access when lifecycle_status is active (accessible)" do
      get "/companies/#{company.id}/dashboards"
      expect(response).to have_http_status(:ok)
    end

    it "allows access when lifecycle_status is active even with future suspension_at" do
      company.update!(suspension_at: 1.week.from_now)
      get "/companies/#{company.id}/dashboards"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "set_billing_warning" do
    before do
      allow(Time).to receive(:current).and_return(Time.new(2026, 6, 20, 10, 0, 0))
      company.update!(has_unpaid_invoices_at: 7.days.ago)
    end

    it "skips the billing warning when hide_billing_alerts is true" do
      company.update!(hide_billing_alerts: true)
      get "/companies/#{company.id}/dashboards"
      expect(flash[:alert]).to be_blank
    end

    it "shows the billing warning when hide_billing_alerts is false" do
      company.update!(hide_billing_alerts: false)
      get "/companies/#{company.id}/dashboards"
      expect(flash[:alert]).not_to be_blank
    end
  end
end
