# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::CompensationService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.employees.find_by(business_type: :owner) }
  let(:manager) do
    create(:employee, company: company, branch: branch).tap { |employee| employee.attach_role("Manager") }
  end
  let(:staff) { create(:employee, company: company, branch: branch) }

  it "assigns the owner and branch managers as reporting lines" do
    manager
    staff

    described_class.assign!(company: company)

    expect(owner.reload.branch).to eq(branch)
    expect(manager.reload.manager).to eq(owner)
    expect(staff.reload.manager).to eq(manager)
  end

  it "assigns salary, allowance, and contract renewal to every employee" do
    manager
    staff

    described_class.assign!(company: company)

    expect(owner.reload.monthly_salary_cents).to be > 0
    expect(owner.expiration_date).to be_present
    expect(manager.reload.monthly_salary_cents).to be > staff.reload.monthly_salary_cents
    expect(staff.monthly_allowance_cents).to be > 0
    expect(staff.expiration_date).to be_present
  end

  it "uses VND salary tiers for VND employees" do
    manager
    company.update!(currency: :vnd)
    manager.update!(currency: :vnd)

    described_class.assign!(company: company)

    expect(manager.reload.monthly_salary_cents).to be >= 40_000_000 * 100
  end

  it "is idempotent when run twice" do
    manager
    staff
    described_class.assign!(company: company)
    original_manager = staff.reload.manager_id
    original_expiration = staff.expiration_date

    expect do
      described_class.assign!(company: company)
    end.not_to change(Employee, :count)

    expect(staff.reload.manager_id).to eq(original_manager)
    expect(staff.expiration_date).to eq(original_expiration)
  end
end
