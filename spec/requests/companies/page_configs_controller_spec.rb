# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PageConfigsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:branch) { create(:branch, company: company) }
  let!(:warehouse) { create(:warehouse, company: company, branch: branch) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    Seed::PageService.seed_defaults!(company: company)
    get sign_in_for_test_path(email: owner.email)
  end

  describe "GET #index" do
    it "lists every company Page with appointment counts" do
      get company_page_configs_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("page_configs").size).to eq(PAGE_TYPES.size)

      pos = body.fetch("page_configs").find { |page| page.fetch("page_type") == "pos" }
      expect(pos.fetch("branch_appointment_count")).to eq(1)
      expect(pos.fetch("page_warehouse_appointment_count")).to eq(0)

      inventory = body.fetch("page_configs").find { |page| page.fetch("page_type") == "inventory" }
      expect(inventory.fetch("page_warehouse_appointment_count")).to eq(1)
    end
  end

  describe "PATCH #update" do
    it "updates metadata and returns the page" do
      page = company.pages.find_by!(page_type: :pos)

      patch company_page_config_path(company, page), params: {
        page: { metadata: { "roles" => [ "Cashier" ], "layout" => { "columns" => 8 } } }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.fetch("message")).to eq("Page config updated.")
      expect(body.fetch("page").fetch("metadata")).to eq(
        "roles" => [ "Cashier" ],
        "layout" => { "columns" => 8 }
      )
      expect(page.reload.metadata).to eq("roles" => [ "Cashier" ], "layout" => { "columns" => 8 })
    end

    it "ignores non-metadata params" do
      page = company.pages.find_by!(page_type: :pos)
      original_name = page.name

      patch company_page_config_path(company, page), params: {
        page: { name: "Hacked", page_type: "booking", metadata: { "roles" => [] } }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(page.reload.name).to eq(original_name)
      expect(page.page_type).to eq("pos")
    end

    it "rejects invalid roles metadata" do
      page = company.pages.find_by!(page_type: :pos)

      patch company_page_config_path(company, page), params: {
        page: { metadata: { "roles" => "Cashier" } }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("errors")).to include("Metadata roles must be an array of strings")
    end

    it "does not expose another company's page" do
      other_company = create(:company)
      other_page = create(:page, company: other_company)

      patch company_page_config_path(company, other_page), params: {
        page: { metadata: { "roles" => [] } }
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
