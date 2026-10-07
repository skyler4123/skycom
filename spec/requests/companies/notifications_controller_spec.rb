# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::NotificationsController", type: :request do
  let(:company) { create(:company) }
  let(:employee) { company.employees.find_by(business_type: "owner") }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }
  let(:other_tag) { NotificationTag.create!(company: company, name: "hr") }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: company.user.email)
    EmployeeNotificationTagAppointment.create!(employee: employee, notification_tag: tag)
  end

  describe "GET #unread_count" do
    it "returns unread count scoped to subscribed tags" do
      Notifications::CreateService.call(company: company, title: "a", tag_ids: [ tag.id ])
      Notifications::CreateService.call(company: company, title: "b", tag_ids: [ other_tag.id ])

      get unread_count_company_notifications_path(company), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["unread_count"]).to eq(1)
    end
  end

  describe "POST #mark_read" do
    it "mark_read is idempotent" do
      notif = Notifications::CreateService.call(company: company, title: "t", tag_ids: [ tag.id ])[:notification]

      post mark_read_company_notification_path(company, notif), as: :json
      post mark_read_company_notification_path(company, notif), as: :json

      expect(response).to have_http_status(:ok)
      expect(EmployeeNotificationRead.where(employee: employee, notification: notif).count).to eq(1)
    end
  end

  describe "POST #mark_all_read" do
    it "mark_all_read twice reads zero the second time" do
      Notifications::CreateService.call(company: company, title: "t", tag_ids: [ tag.id ])

      post mark_all_read_company_notifications_path(company), as: :json
      expect(JSON.parse(response.body)["marked"]).to be >= 1

      post mark_all_read_company_notifications_path(company), as: :json
      expect(JSON.parse(response.body)["marked"]).to eq(0)
    end
  end

  describe "GET #index" do
    it "lists subscribed notifications with pagination" do
      Notifications::CreateService.call(company: company, title: "hello", tag_ids: [ tag.id ])

      get company_notifications_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["notifications"].size).to eq(1)
      expect(body).to have_key("pagination")
    end
  end
end
