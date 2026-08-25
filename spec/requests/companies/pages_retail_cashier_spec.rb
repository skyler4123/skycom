# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PagesController#retail_cashier", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company) }
  let(:page_record) { create(:page, company: company, branch: branch, target_role: :retail_cashier) }

  let(:cash_pm) do
    PaymentMethod.create!(name: "Cash Page", code: "PG_CASH", business_type: :b2c,
      payment_mode: :cash, strategy: :cash)
  end
  let(:qr_pm) do
    PaymentMethod.create!(name: "Mock QR Page", code: "PG_MQR", business_type: :b2c,
      payment_mode: :qr, strategy: :mock_qr_gateway)
  end
  let(:redirect_pm) do
    PaymentMethod.create!(name: "Mock Redirect Page", code: "PG_RD", business_type: :b2c,
      payment_mode: :redirect, strategy: :mock_redirect_gateway)
  end

  let!(:initialized_branch) { branch }
  let!(:appts) do
    [ cash_pm, qr_pm, redirect_pm ].flat_map do |pm|
      [
        PaymentMethodAppointment.create!(appoint_to: company, company: company, payment_method: pm,
          name: "Co #{pm.code}", code: "PG_CO_#{pm.code}", business_type: :in_store, lifecycle_status: :active),
        PaymentMethodAppointment.create!(appoint_to: branch, company: company, payment_method: pm,
          name: "Br #{pm.code}", code: "PG_BR_#{pm.code}", business_type: :in_store,
          lifecycle_status: :active,
          merchant_number: pm.qr? ? "3333333333" : nil,
          merchant_name: pm.qr? ? "Page Shop" : nil,
          merchant_id: pm.qr? ? "T-PG01" : nil)
      ]
    end
  end

  before { get sign_in_for_test_path(email: company_user.email) }

  it "lists active branch methods excluding redirect mode" do
    get "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier", as: :json

    expect(response).to have_http_status(:ok)
    methods = JSON.parse(response.body)["payment_methods"]
    codes = methods.map { |m| m["code"] }

    expect(methods.length).to eq(2)
    expect(codes).to include("PG_CASH", "PG_MQR")
    expect(codes).not_to include("PG_RD")
    expect(methods.first.keys).to include("id", "name", "code", "payment_mode", "strategy")
  end
end
