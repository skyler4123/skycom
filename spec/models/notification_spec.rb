require "rails_helper"

RSpec.describe Notification do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:other_employee) { create(:employee, company: company, business_type: :full_time) }

  it "belongs to company" do
    expect(Notification.new(company: company, name: "t")).to be_valid
  end

  it "shows a directly addressed notification only to its recipient" do
    notification = Notification.create!(company: company, name: "Guest arrived", recipient_employee: employee)

    expect(Notification.subscribed_for(employee, company)).to include(notification)
    expect(Notification.subscribed_for(other_employee, company)).not_to include(notification)
  end

  it "still shows tag-visible notifications to subscribers" do
    tag = NotificationTag.create!(company: company, name: "ops")
    EmployeeNotificationTagAppointment.create!(employee: employee, notification_tag: tag)
    notification = Notification.create!(company: company, name: "Broadcast")
    NotificationTagAppointment.create!(company: company, notification: notification, notification_tag: tag)

    expect(Notification.subscribed_for(employee, company)).to include(notification)
    expect(Notification.subscribed_for(other_employee, company)).not_to include(notification)
  end
end
