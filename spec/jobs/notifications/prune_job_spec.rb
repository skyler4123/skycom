require "rails_helper"

RSpec.describe Notifications::PruneJob, type: :job do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  it "prunes notifications older than retention" do
    old = Notifications::CreateService.call(company: company, title: "old", tag_ids: [ tag.id ])[:notification]
    old.update_column(:created_at, 100.days.ago)
    fresh = Notifications::CreateService.call(company: company, title: "fresh", tag_ids: [ tag.id ])[:notification]

    described_class.perform_now

    expect(Notification.exists?(old.id)).to be(false)
    expect(Notification.exists?(fresh.id)).to be(true)
  end

  it "clears cached bell counts for affected employees" do
    employee = create(:employee, company: company, business_type: :full_time)
    tag = NotificationTag.create!(company: company, name: "ops")
    EmployeeNotificationTagAppointment.create!(employee: employee, notification_tag: tag)
    old = Notifications::CreateService.call(company: company, title: "old", tag_ids: [ tag.id ])[:notification]
    old.update_column(:created_at, 100.days.ago)
    NotificationConfig.for_employee!(employee).update!(last_read_all_at: 101.days.ago)

    expect(Notifications::UnreadQuery.new(company: company, employee: employee).count).to eq(1)
    described_class.perform_now

    expect(Rails.sync_cache.read(Notifications::UnreadQuery.cache_key(employee.id))).to be_nil
  end
end
