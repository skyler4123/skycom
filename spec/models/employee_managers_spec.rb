# spec/models/employee_managers_spec.rb
require "rails_helper"

RSpec.describe "Employee#managers", type: :model do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }
  let(:manager) { create(:employee, company: company, branch: branch, name: "Alex Manager") }
  let(:other_manager) { create(:employee, company: company, branch: branch, name: "Blair Manager") }

  def enroll(employee, employee_group)
    create(
      :employee_employee_group_appointment,
      company: company,
      employee: employee,
      employee_group: employee_group
    )
  end

  it "returns the distinct managers of the employee's groups" do
    first_group = create(:employee_group, company: company, manager: manager)
    second_group = create(:employee_group, company: company, manager: other_manager)
    enroll(employee, first_group)
    enroll(employee, second_group)

    expect(employee.managers).to contain_exactly(manager, other_manager)
  end

  it "does not return the employee as their own manager" do
    enroll(employee, create(:employee_group, company: company, manager: employee))

    expect(employee.managers).to be_empty
  end

  it "does not return a discarded manager" do
    enroll(employee, create(:employee_group, company: company, manager: manager))
    manager.discard!

    expect(employee.managers).to be_empty
  end

  it "caches manager ids for one hour" do
    enroll(employee, create(:employee_group, company: company, manager: manager))

    expect(Rails.sync_cache).to receive(:fetch)
      .with("employees_#{employee.id}:managers", expires_in: 1.hour)
      .and_call_original

    employee.managers
  end

  it "clears the cache when a group membership is added" do
    employee.managers

    enroll(employee, create(:employee_group, company: company, manager: manager))

    expect(employee.managers).to contain_exactly(manager)
  end

  it "clears the cache when the group manager changes" do
    group = create(:employee_group, company: company, manager: manager)
    enroll(employee, group)
    employee.managers

    group.update!(manager: other_manager)

    expect(employee.managers).to contain_exactly(other_manager)
  end
end
