require "rails_helper"

RSpec.describe Notifications::CreateService do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  it "creates a notification with tag links" do
    res = described_class.call(company: company, title: "hello", tag_ids: [ tag.id ])
    expect(res[:success]).to be(true)
    expect(res[:notification].notification_tags.map(&:id)).to include(tag.id)
  end

  it "throttles duplicate tag events" do
    described_class.call(company: company, title: "t", tag_ids: [ tag.id ],
      throttle_key: "stock:1", throttle_window: 1.hour)
    res = described_class.call(company: company, title: "t", tag_ids: [ tag.id ],
      throttle_key: "stock:1", throttle_window: 1.hour)
    expect(res[:success]).to be(false)
  end
end

RSpec.describe Notifications::UnreadQuery do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }
  let(:other_tag) { NotificationTag.create!(company: company, name: "hr") }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }

  before do
    EmployeeNotificationTagAppointment.create!(employee: employee, notification_tag: tag)
  end

  it "counts only subscribed tags" do
    Notifications::CreateService.call(company: company, title: "a", tag_ids: [ tag.id ])
    Notifications::CreateService.call(company: company, title: "b", tag_ids: [ other_tag.id ])
    expect(described_class.new(company: company, employee: employee).count).to eq(1)
  end

  it "new hire sees zero unread" do
    Notifications::CreateService.call(company: company, title: "old", tag_ids: [ tag.id ])
    new_hire = create(:employee, company: company, business_type: :full_time)
    EmployeeNotificationTagAppointment.create!(employee: new_hire, notification_tag: tag)
    expect(described_class.new(company: company, employee: new_hire).count).to eq(0)
  end
end

RSpec.describe Notifications::MarkReadService do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:notif) { Notifications::CreateService.call(company: company, title: "t", tag_ids: [ tag.id ])[:notification] }

  it "is idempotent" do
    first = described_class.call(employee: employee, notification: notif)
    second = described_class.call(employee: employee, notification: notif)
    expect(first[:success]).to be(true)
    expect(second[:success]).to be(true)
    expect(EmployeeNotificationRead.where(employee: employee, notification: notif).count).to eq(1)
  end
end

RSpec.describe Notifications::MarkAllReadService do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }

  before do
    EmployeeNotificationTagAppointment.create!(employee: employee, notification_tag: tag)
    Notifications::CreateService.call(company: company, title: "a", tag_ids: [ tag.id ])
  end

  it "marks all then zero the second time" do
    first = described_class.call(employee: employee)
    expect(first[:marked]).to be >= 1
    second = described_class.call(employee: employee)
    expect(second[:marked]).to eq(0)
  end
end
