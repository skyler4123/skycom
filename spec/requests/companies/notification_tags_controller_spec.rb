# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::NotificationTagsController", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before { get sign_in_for_test_path(email: owner.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    let!(:tag) { NotificationTag.create!(company: company, name: "ops", business_type: :custom) }

    it "returns tags scoped to the company" do
      get company_notification_tags_path(company, format: :json)

      names = JSON.parse(response.body)["notification_tags"].map { |t| t["name"] }
      expect(names).to include("ops")
    end
  end

  describe "POST #create" do
    it "creates a custom tag and redirects to show" do
      expect {
        post company_notification_tags_path(company),
          params: { notification_tag: { name: "night-shift", description: "Nights" } }
      }.to change(NotificationTag, :count).by(1)

      tag = NotificationTag.find_by(company: company, name: "night-shift")
      expect(tag.business_type).to eq("custom")
      expect(response).to redirect_to(company_notification_tag_path(company, tag))
    end

    it "rejects a duplicate name and creates nothing" do
      NotificationTag.create!(company: company, name: "ops", business_type: :custom)

      expect {
        post company_notification_tags_path(company),
          params: { notification_tag: { name: "ops", description: "dup" } }
      }.to change(NotificationTag, :count).by(0)

      expect(response).to redirect_to(new_company_notification_tag_path(company))
    end

    it "ignores business_type param and stays custom" do
      post company_notification_tags_path(company),
        params: { notification_tag: { name: "sneaky", business_type: "system" } }

      expect(NotificationTag.find_by(company: company, name: "sneaky").business_type).to eq("custom")
    end
  end

  describe "PATCH #update" do
    let!(:tag) { NotificationTag.create!(company: company, name: "ops", business_type: :custom) }

    it "renames the tag and redirects to show" do
      patch company_notification_tag_path(company, tag),
        params: { notification_tag: { name: "ops-updated" } }

      expect(tag.reload.name).to eq("ops-updated")
      expect(response).to redirect_to(company_notification_tag_path(company, tag))
    end
  end

  describe "DELETE #destroy" do
    it "destroys a custom tag and redirects to index" do
      tag = NotificationTag.create!(company: company, name: "ops", business_type: :custom)

      expect {
        delete company_notification_tag_path(company, tag)
      }.to change(NotificationTag, :count).by(-1)

      expect(response).to redirect_to(company_notification_tags_path(company))
    end

    it "refuses to destroy a system tag and keeps the row" do
      tag = NotificationTag.create!(company: company, name: "All Employees", business_type: :system)

      expect {
        delete company_notification_tag_path(company, tag)
      }.to change(NotificationTag, :count).by(0)

      expect(response).to redirect_to(company_notification_tag_path(company, tag))
    end

    it "404s for a tag from another company" do
      foreign = NotificationTag.create!(company: create(:company), name: "ops", business_type: :custom)

      expect {
        delete company_notification_tag_path(company, foreign)
      }.to change(NotificationTag, :count).by(0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
