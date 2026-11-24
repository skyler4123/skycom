# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::FaqsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /companies/:company_id/faq" do
    it "renders the shell for an employee" do
      get sign_in_for_test_path(email: owner.email)
      get company_faq_path(company), headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("companies--faqs--show")
    end

    it "stays available while the company is suspended" do
      company.update_columns(workflow_status: Company.workflow_statuses[:suspend])
      Rails.ram_cache.delete(CacheKeyService.company_suspended(company.id))
      Rails.sync_cache.delete(CacheKeyService.company(company.id))

      get sign_in_for_test_path(email: owner.email)
      get company_faq_path(company), headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
    end

    it "redirects an employee from another company" do
      other_company = create(:company)

      get sign_in_for_test_path(email: other_company.user.email)
      get company_faq_path(company), headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:redirect)
    end
  end
end
