require "rails_helper"

RSpec.describe EmployeeNotificationRead, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:notif) { Notification.create!(company: company, title: "t") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:notification) }
  end

  it "rejects duplicate read" do
    EmployeeNotificationRead.create!(company: company, employee: employee, notification: notif)
    expect(EmployeeNotificationRead.new(company: company, employee: employee, notification: notif)).not_to be_valid
  end
end
