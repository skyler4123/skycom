# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Credit deduction on priced pages", type: :request do
  let(:company) { create(:company, :without_signup_promo, country: :us, currency: :usd) }
  let(:owner) { company.user }
  let(:wallet) { company.company_wallet }
  let!(:branch) { create(:branch, company: company, timezone: :utc) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  let!(:pos_operation) { create(:operation, company: company, branch: branch, operation_type: :pos) }
  let!(:booking_operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let!(:reception_operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let!(:store_manager_operation) { create(:operation, company: company, branch: branch, operation_type: :store_manager) }
  let!(:inventory_operation) { create(:operation, company: company, operation_type: :inventory) }
  let!(:inventory_appointment) do
    create(:operation_warehouse_appointment,
      company: company, operation: inventory_operation, warehouse: warehouse)
  end

  before do
    wallet.add_credits!(amount: 1_000)
    get sign_in_for_test_path(email: owner.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def token_for(path, params = {})
    get path, params: params
    expect(response).to have_http_status(:ok)

    Nokogiri::HTML(response.body).at_css("body")["data-credit-page-token"]
  end

  def get_json(path, token, params = {})
    get path, params: params, headers: { "X-Credit-Page-Token" => token }
  end

  describe "dashboard index" do
    it "does not charge the HTML shell" do
      token = token_for(company_dashboards_path(company))

      expect(token).to be_present
      expect(wallet.reload.main_credit_balance).to eq(1_000)
    end

    it "charges 2 once for the first JSON request and not the next" do
      token = token_for(company_dashboards_path(company))

      2.times { get_json(company_dashboards_path(company, format: :json), token) }

      expect(wallet.reload.main_credit_balance).to eq(998)
      expect(company.credit_usage_delta).to eq(2)
    end

    it "charges again for a new page load" do
      2.times do
        token = token_for(company_dashboards_path(company))
        get_json(company_dashboards_path(company, format: :json), token)
      end

      expect(wallet.reload.main_credit_balance).to eq(996)
    end
  end

  describe "analytics index" do
    it "charges 2 once and does not re-charge when the period changes" do
      token = token_for(company_analytics_path(company))

      get_json(company_analytics_path(company, format: :json), token, period: "this_month")
      get_json(company_analytics_path(company, format: :json), token, period: "last_month")

      expect(wallet.reload.main_credit_balance).to eq(998)
      expect(company.credit_usage_delta).to eq(2)
    end
  end

  describe "operation consoles" do
    it "charges 3 for POS and not for a later JSON call" do
      path = pos_company_operations_path(company, pos_operation)
      token = token_for(path, branch_id: branch.id)

      get_json("#{path}.json", token, branch_id: branch.id)
      get_json("#{path}.json", token, branch_id: branch.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
      expect(company.credit_usage_delta).to eq(3)
    end

    it "charges 3 for Booking" do
      path = booking_company_operations_path(company, booking_operation)
      token = token_for(path, branch_id: branch.id)

      get_json("#{path}.json", token, branch_id: branch.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
    end

    it "charges 3 for Reception" do
      path = reception_company_operations_path(company, reception_operation)
      token = token_for(path, branch_id: branch.id)

      get_json("#{path}.json", token, branch_id: branch.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
    end

    it "charges 3 for Store Manager" do
      path = store_manager_company_operations_path(company, store_manager_operation)
      token = token_for(path, branch_id: branch.id)

      get_json("#{path}.json", token, branch_id: branch.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
    end

    it "charges 3 for Inventory" do
      path = inventory_company_operations_path(company, inventory_operation)
      token = token_for(path, warehouse_id: warehouse.id)

      get_json("#{path}.json", token, warehouse_id: warehouse.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
    end

    it "charges 3 for a mobile shell consumed by the web JSON endpoint" do
      mobile_path = mobile_company_pos_path(company, pos_operation, branch_id: branch.id)
      web_path = pos_company_operations_path(company, pos_operation)

      token = token_for(mobile_path, branch_id: branch.id)
      expect(token).to be_present
      expect(wallet.reload.main_credit_balance).to eq(1_000)

      get_json("#{web_path}.json", token, branch_id: branch.id)

      expect(wallet.reload.main_credit_balance).to eq(997)
      expect(company.credit_usage_delta).to eq(3)
    end
  end
end
