# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::NotifyCreatorService do
  let!(:company) { create(:company) }
  let(:import) { create(:import, company: company) }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def notify(**overrides)
    described_class.call(
      **{
        import: import,
        name: "Import 'X' finished",
        description: "2 of 2 rows imported (0 failed).",
        severity: :info,
        throttle_key: "import:test:finished"
      }.merge(overrides)
    )
  end

  it "creates the tag once, subscribes the creator, and notifies" do
    result = notify

    expect(result[:success]).to be(true)
    tag = NotificationTag.find_by!(company: company, name: IMPORT_NOTIFICATION_TAG)
    expect(tag.business_type).to eq("system")
    expect(EmployeeNotificationTagAppointment.exists?(employee: import.creator, notification_tag: tag)).to be(true)
    expect(Notification.where(company: company).count).to eq(1)

    notify(name: "Import 'X' finished again", throttle_key: "other")

    expect(NotificationTag.where(company: company, name: IMPORT_NOTIFICATION_TAG).count).to eq(1)
    expect(Notification.where(company: company).count).to eq(2)
  end

  it "throttles per throttle_key" do
    notify

    result = notify

    expect(result[:success]).to be(false)
    expect(Notification.where(company: company).count).to eq(1)
  end

  it "reports a missing creator" do
    allow(import).to receive(:creator).and_return(nil)

    result = notify

    expect(result[:success]).to be(false)
    expect(result[:errors]).to include("creator not found")
  end
end
