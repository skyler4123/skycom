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

    it "never returns another company's notifications even with a forged tag link" do
      other = create(:company)
      foreign = Notification.create!(company: other, title: "foreign")
      NotificationTagAppointment.create!(company: other, notification: foreign, notification_tag: tag)

      get company_notifications_path(company), as: :json

      titles = JSON.parse(response.body)["notifications"].map { |n| n["title"] }
      expect(titles).not_to include("foreign")
    end

    it "issues a single reads query for a mixed read/unread page" do
      3.times do |i|
        Notifications::CreateService.call(company: company, title: "n#{i}", tag_ids: [ tag.id ])
      end
      first = Notification.subscribed_for(employee, company).first
      EmployeeNotificationRead.create!(company: company, employee: employee, notification: first)

      reads_queries = []
      callback = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        reads_queries << payload[:sql] if payload[:sql].include?("employee_notification_reads")
      end
      get company_notifications_path(company), as: :json
      ActiveSupport::Notifications.unsubscribe(callback)

      selects = reads_queries.count { |sql| sql.start_with?("SELECT") }
      expect(selects).to eq(1)
      flags = JSON.parse(response.body)["notifications"].to_h { |n| [ n["title"], n["read"] ] }
      expect(flags["n0"]).to be(true)
    end
  end

  describe "GET #show" do
    it "returns the subscribed notification marked read" do
      notif = Notifications::CreateService.call(company: company, title: "hello", tag_ids: [ tag.id ])[:notification]

      get company_notification_path(company, notif), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["notification"]["title"]).to eq("hello")
      expect(body["notification"]["read"]).to be(true)
      expect(body["notification"]["tags"].map { |t| t["name"] }).to include("ops")
    end

    it "404s a notification from another company" do
      other = create(:company)
      foreign = Notification.create!(company: other, title: "foreign")

      get company_notification_path(company, foreign), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
