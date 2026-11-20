require "rails_helper"

RSpec.describe Notifications::CreateService do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  it "creates a notification with tag links" do
    res = described_class.call(company: company, name: "hello", tag_ids: [ tag.id ])
    expect(res[:success]).to be(true)
    expect(res[:notification].notification_tags.map(&:id)).to include(tag.id)
  end

  it "rejects tags from another company" do
    foreign_tag = NotificationTag.create!(company: create(:company), name: "ops")
    res = described_class.call(company: company, name: "x", tag_ids: [ foreign_tag.id ])
    expect(res[:success]).to be(false)
  end

  it "throttles duplicate tag events" do
    described_class.call(company: company, name: "t", tag_ids: [ tag.id ],
      throttle_key: "stock:1", throttle_window: 1.hour)
    res = described_class.call(company: company, name: "t", tag_ids: [ tag.id ],
      throttle_key: "stock:1", throttle_window: 1.hour)
    expect(res[:success]).to be(false)
  end

  it "creates a direct notification without a tag" do
    employee = create(:employee, company: company, business_type: :full_time)
    res = described_class.call(company: company, name: "Guest arrived", recipient_employee: employee)

    expect(res[:success]).to be(true)
    expect(res[:notification].recipient_employee).to eq(employee)
    expect(res[:notification].notification_tags).to be_empty
  end

  it "rejects a recipient from another company" do
    foreign_employee = create(:employee, company: create(:company), business_type: :full_time)
    res = described_class.call(company: company, name: "x", recipient_employee: foreign_employee)

    expect(res[:success]).to be(false)
    expect(res[:errors]).to contain_exactly("Unknown recipient")
  end

  it "requires a tag or a recipient" do
    res = described_class.call(company: company, name: "x")

    expect(res[:success]).to be(false)
    expect(res[:errors]).to contain_exactly("At least one tag or recipient is required")
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
    Notifications::CreateService.call(company: company, name: "a", tag_ids: [ tag.id ])
    Notifications::CreateService.call(company: company, name: "b", tag_ids: [ other_tag.id ])
    expect(described_class.new(company: company, employee: employee).count).to eq(1)
  end

  it "counts a directly addressed notification even without a tag subscription" do
    direct = create(:employee, company: company, business_type: :full_time)
    Notifications::CreateService.call(company: company, name: "Guest arrived", recipient_employee: direct)

    expect(described_class.new(company: company, employee: direct).count).to eq(1)
  end

  it "new hire sees zero unread" do
    Notifications::CreateService.call(company: company, name: "old", tag_ids: [ tag.id ])
    new_hire = create(:employee, company: company, business_type: :full_time)
    EmployeeNotificationTagAppointment.create!(employee: new_hire, notification_tag: tag)
    expect(described_class.new(company: company, employee: new_hire).count).to eq(0)
  end

  it "does not create a config row on read paths" do
    Notifications::CreateService.call(company: company, name: "a", tag_ids: [ tag.id ])

    expect {
      described_class.new(company: company, employee: employee).count
      described_class.new(company: company, employee: employee).scope.to_a
    }.not_to change(NotificationConfig, :count)
  end
end

RSpec.describe Notifications::MarkReadService do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:notif) { Notifications::CreateService.call(company: company, name: "t", tag_ids: [ tag.id ])[:notification] }

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
    Notifications::CreateService.call(company: company, name: "a", tag_ids: [ tag.id ])
  end

  it "marks all then zero the second time" do
    first = described_class.call(employee: employee)
    expect(first[:marked]).to be >= 1
    second = described_class.call(employee: employee)
    expect(second[:marked]).to eq(0)
  end
end
