require "rails_helper"

RSpec.describe "notification auto-subscribe" do
  let(:company) { create(:company) }
  let!(:all_company) do
    NotificationTag.create!(company: company, name: "All Company", business_type: :system)
  end
  let!(:all_cashier) do
    NotificationTag.create!(company: company, name: "All Cashier", business_type: :system)
  end

  it "subscribes a new employee to All Company" do
    employee = create(:employee, company: company, business_type: :full_time)
    expect(employee.subscribed_notification_tags).to include(all_company)
  end

  it "subscribes an employee to their role tag on role assignment" do
    role = Seed::RoleService.create(company: company, name: "Cashier")
    employee = create(:employee, company: company, business_type: :full_time)
    employee.attach_role(role.name)
    expect(employee.reload.subscribed_notification_tags).to include(all_cashier, all_company)
  end

  it "does nothing when tags do not exist (legacy company)" do
    legacy = create(:company)
    expect {
      create(:employee, company: legacy, business_type: :full_time)
    }.not_to raise_error
  end
end
