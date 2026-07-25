# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PaymentMethodAppointmentsController", type: :request do
  let(:company) { create(:company).tap { |c| c.update_column(:country, 840) } }
  let(:owner_user) { company.user }

  let!(:pm_cash) { create(:payment_method, name: "Cash", code: "CASH", country: 840, strategy: :cash, payment_mode: :cash) }

  let!(:appointment_cash) do
    PaymentMethodAppointment.create!(
      company: company, payment_method: pm_cash,
      name: "Cash for #{company.name}",
      code: "CASH-#{SecureRandom.hex(4).upcase}",
      business_type: :in_store, lifecycle_status: :active
    )
  end

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/payment_method_appointments" do
    it "returns http ok" do
      get "/companies/#{company.id}/payment_method_appointments", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns only existing appointments (no lazy creation)" do
      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      expect(body["payment_method_appointments"].size).to eq(1)
    end

    it "includes payment method metadata" do
      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      app = body["payment_method_appointments"].first
      expect(app["name"]).to eq("Cash")
      expect(app["code"]).to eq("CASH")
      expect(app["payment_mode"]).to eq("cash")
      expect(app["lifecycle_status"]).to eq("active")
      expect(app["strategy"]).to eq("cash")
    end

    it "scopes appointments to the current company" do
      other_company = create(:company).tap { |c| c.update_column(:country, 840) }
      other_pm = create(:payment_method, country: 840, strategy: :cash)
      PaymentMethodAppointment.create!(
        company: other_company, payment_method: other_pm,
        name: "Other", code: "OTHER-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store, lifecycle_status: :inactive
      )

      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      expect(body["payment_method_appointments"].size).to eq(1)
    end
  end
end
