# frozen_string_literal: true

require "rails_helper"

RSpec.describe Companies::ImportsPolicy do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: OWNER_BUSINESS_TYPE) }

  it "grants the owner every action" do
    policy = described_class.new(owner, owner)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.create?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
    expect(policy.source_file?).to be(true)
    expect(policy.dry_run?).to be(true)
    expect(policy.approve?).to be(true)
    expect(policy.rollback?).to be(true)
  end

  it "denies a non-owner employee" do
    employee = create(:employee, company: company)
    policy = described_class.new(employee, employee)

    expect(policy.index?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.approve?).to be(false)
    expect(policy.rollback?).to be(false)
  end

  it "stays owner-only even when ABAC grants exist" do
    employee = create(:employee, company: company)
    allow(employee).to receive(:can?).and_return(true)
    policy = described_class.new(employee, employee)

    expect(policy.index?).to be(false)
    expect(policy.source_file?).to be(false)
  end
end
