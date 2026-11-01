# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::NotifyOwnerService do
  let!(:company) { create(:company) }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def notify(**overrides)
    described_class.call(
      **{
        company: company,
        name: "Migration 'X' finished",
        description: "10 of 10 rows imported (0 failed).",
        severity: :info,
        throttle_key: "company_migration:test:finished"
      }.merge(overrides)
    )
  end

  describe ".call" do
    it "creates the tag once and notifies the owner" do
      result = notify

      expect(result[:success]).to be(true)
      tag = NotificationTag.find_by!(company: company, name: MIGRATION_NOTIFICATION_TAG)
      expect(tag.business_type).to eq("system")

      owner = company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
      expect(EmployeeNotificationTagAppointment.exists?(employee: owner, notification_tag: tag)).to be(true)
      expect(Notification.where(company: company).count).to eq(1)

      notify(name: "Migration 'X' finished again", throttle_key: "other")

      expect(NotificationTag.where(company: company, name: MIGRATION_NOTIFICATION_TAG).count).to eq(1)
      expect(Notification.where(company: company).count).to eq(2)
    end

    it "throttles per throttle_key" do
      notify

      result = notify

      expect(result[:success]).to be(false)
      expect(Notification.where(company: company).count).to eq(1)
    end
  end
end
