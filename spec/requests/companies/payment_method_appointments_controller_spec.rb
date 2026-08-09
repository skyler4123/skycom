# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PaymentMethodAppointmentsController", type: :request do
  let(:company) { create(:company).tap { |c| c.update!(country: :us) } }
  let(:owner_user) { company.user }

  let!(:pm_cash) { create(:payment_method, name: "Cash", code: "CASH", country: 840, strategy: :cash, payment_mode: :cash) }

  let!(:appointment_cash) do
      PaymentMethodAppointment.create!(
        company: company, payment_method: pm_cash,
        name: "Cash for #{company.name}",
        code: "CASH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store, lifecycle_status: :active,
        merchant_number: nil, merchant_name: nil, merchant_id: nil
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

    it "includes payment method metadata and merchant fields" do
      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      app = body["payment_method_appointments"].first
      expect(app["name"]).to eq("Cash")
      expect(app["code"]).to eq("CASH")
      expect(app["payment_mode"]).to eq("cash")
      expect(app["lifecycle_status"]).to eq("active")
      expect(app["strategy"]).to eq("cash")
      expect(app).to have_key("merchant_number")
      expect(app).to have_key("merchant_name")
      expect(app).to have_key("merchant_id")
    end

    it "returns merchant fields as null for cash payments" do
      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      app = body["payment_method_appointments"].first
      expect(app["merchant_number"]).to be_nil
      expect(app["merchant_name"]).to be_nil
      expect(app["merchant_id"]).to be_nil
    end
  end

  describe "GET /companies/:company_id/payment_method_appointments/:id/edit" do
    it "returns merchant fields in edit JSON" do
      get "/companies/#{company.id}/payment_method_appointments/#{appointment_cash.id}/edit", as: :json
      body = JSON.parse(response.body)
      a = body["payment_method_appointment"]
      expect(a).to have_key("merchant_number")
      expect(a).to have_key("merchant_name")
      expect(a).to have_key("merchant_id")
      expect(a["merchant_number"]).to be_nil
    end
  end

  describe "PATCH /companies/:company_id/payment_method_appointments/:id" do
    it "updates merchant fields" do
      patch "/companies/#{company.id}/payment_method_appointments/#{appointment_cash.id}",
        params: { payment_method_appointment: { merchant_number: "9876543210", merchant_name: "Test Business", merchant_id: "MID-TEST" } }
      expect(response).to have_http_status(:redirect)
      appointment_cash.reload
      expect(appointment_cash.merchant_number).to eq("9876543210")
      expect(appointment_cash.merchant_name).to eq("Test Business")
      expect(appointment_cash.merchant_id).to eq("MID-TEST")
    end
  end

  describe "scoping" do
    it "scopes appointments to the current company" do
      other_company = create(:company).tap { |c| c.update!(country: :us) }
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

    it "excludes branch-level appointments from the index" do
      branch = create(:branch, company: company)
      branch.payment_method_appointments.find_by!(payment_method: pm_cash)

      get "/companies/#{company.id}/payment_method_appointments", as: :json
      body = JSON.parse(response.body)
      expect(body["payment_method_appointments"].size).to eq(1)
      expect(body["payment_method_appointments"].map { |a| a["id"] }).to eq([ appointment_cash.id ])
    end

    it "returns branch-level appointments when filtered by branch_id" do
      branch = create(:branch, company: company)
      branch_appointment = branch.payment_method_appointments.find_by!(payment_method: pm_cash)

      get "/companies/#{company.id}/payment_method_appointments", params: { branch_id: branch.id }, as: :json
      body = JSON.parse(response.body)
      expect(body["payment_method_appointments"].size).to eq(1)
      expect(body["payment_method_appointments"].first["id"]).to eq(branch_appointment.id)
      expect(body["payment_method_appointments"].first["company_level_active"]).to eq(true)
    end

    it "reports company_level_active false when the company-level method is inactive" do
      branch = create(:branch, company: company)
      branch.payment_method_appointments.find_by!(payment_method: pm_cash)
      appointment_cash.update_column(:lifecycle_status, PaymentMethodAppointment.lifecycle_statuses.fetch("inactive"))

      get "/companies/#{company.id}/payment_method_appointments", params: { branch_id: branch.id }, as: :json
      body = JSON.parse(response.body)
      expect(body["payment_method_appointments"].first["company_level_active"]).to eq(false)
    end
  end

  describe "branch-level appointment lifecycle" do
    let!(:branch) { create(:branch, company: company) }
    let!(:branch_appointment) { branch.payment_method_appointments.find_by!(payment_method: pm_cash) }

    it "returns the branch-level appointment in edit JSON" do
      get "/companies/#{company.id}/payment_method_appointments/#{branch_appointment.id}/edit", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["payment_method_appointment"]["id"]).to eq(branch_appointment.id)
      expect(body["payment_method_appointment"]["lifecycle_status"]).to eq("active")
    end

    it "updates branch-level lifecycle_status via PATCH" do
      patch "/companies/#{company.id}/payment_method_appointments/#{branch_appointment.id}",
        params: { payment_method_appointment: { lifecycle_status: "inactive" } }
      expect(response).to have_http_status(:redirect)

      branch_appointment.reload
      expect(branch_appointment.lifecycle_status).to eq("inactive")
    end
  end
end
