# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::PagesController", type: :request do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { create(:company, user: company_user, business_type: :retail) }
  let(:branch) { create(:branch, company: company) }

  let!(:cashier_desktop) do
    create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :desktop)
  end
  let!(:cashier_mobile) do
    create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :mobile)
  end
  let!(:manager_desktop) do
    create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :desktop)
  end
  let!(:manager_mobile) do
    create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :mobile)
  end

  before { get sign_in_for_test_path(email: company_user.email) }

  describe "GET #index" do
    it "lists only desktop pages and returns company-wide resolution counts" do
      get "/companies/#{company.id}/pages.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["pages"].map { |p| p["target_role"] }).to contain_exactly(
        "retail_cashier", "retail_store_manager"
      )
      expect(body["pages"].map { |p| p["target_resolution"] }).to all(eq("desktop"))
      expect(body["summary"]).to eq("total" => 4, "desktop" => 2, "mobile" => 2)
      expect(body["pages"].find { |p| p["target_role"] == "retail_cashier" }["placeholder"]).to be(false)
      expect(body["pages"].find { |p| p["target_role"] == "retail_store_manager" }["placeholder"]).to be(true)
    end

    it "does not list pages from another business type" do
      restaurant = create(:company, business_type: :restaurant)
      restaurant_branch = create(:branch, company: restaurant)
      create(:page, company: restaurant, branch: restaurant_branch,
        target_role: :restaurant_cashier, target_resolution: :desktop)

      get "/companies/#{company.id}/pages.json"

      expect(JSON.parse(response.body)["pages"].map { |p| p["target_role"] }).not_to include("restaurant_cashier")
    end

    it "scopes the summary to the selected branch" do
      other_branch = create(:branch, company: company)
      create(:page, company: company, branch: other_branch,
        target_role: :retail_cashier, target_resolution: :desktop)

      get "/companies/#{company.id}/pages.json", params: { branch_id: branch.id }

      expect(JSON.parse(response.body)["summary"]).to eq("total" => 4, "desktop" => 2, "mobile" => 2)
    end
  end

  describe "GET #launch" do
    it "returns the placeholder payload for a not-yet-built page" do
      get "/companies/#{company.id}/pages/#{manager_desktop.id}/launch.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["placeholder"]).to be(true)
      expect(body["page"]["name"]).to eq("Retail Store Manager Desktop")
    end

    it "returns the launch path for the implemented desktop cashier page" do
      get "/companies/#{company.id}/pages/#{cashier_desktop.id}/launch.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["placeholder"]).to be(false)
      expect(body["launch_path"]).to eq(
        "/companies/#{company.id}/pages/#{cashier_desktop.id}/retail_cashier"
      )
    end

    it "redirects an HTML launch of an implemented page to its real screen" do
      get "/companies/#{company.id}/pages/#{cashier_desktop.id}/launch"

      expect(response).to redirect_to(
        "/companies/#{company.id}/pages/#{cashier_desktop.id}/retail_cashier"
      )
    end

    it "renders the Shell-First layout for an HTML placeholder launch" do
      get "/companies/#{company.id}/pages/#{manager_desktop.id}/launch"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="companies--pages--launch"')
    end
  end

  describe "GET #new" do
    it "returns only the target roles for the company business type" do
      get "/companies/#{company.id}/pages/new.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["business_type"]).to eq("retail")
      expect(body["target_roles"].map { |r| r["value"] }).to contain_exactly(
        "retail_cashier", "retail_store_manager"
      )
    end
  end

  describe "GET #show" do
    it "returns the page plus the company's target roles" do
      get "/companies/#{company.id}/pages/#{cashier_desktop.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["page"]["placeholder"]).to be(false)
      expect(body["target_roles"].map { |r| r["value"] }).to contain_exactly(
        "retail_cashier", "retail_store_manager"
      )
    end
  end
end
