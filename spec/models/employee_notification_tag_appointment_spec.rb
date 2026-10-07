require "rails_helper"

RSpec.describe EmployeeNotificationTagAppointment, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:notification_tag) }
  end

  it "derives company_id from employee" do
    row = EmployeeNotificationTagAppointment.new(employee: employee, notification_tag: tag)
    row.valid?
    expect(row.company_id).to eq(company.id)
  end
end
