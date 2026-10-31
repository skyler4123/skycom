# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mobile::Companies::AttendanceRequestsPolicy do
  subject(:policy) { described_class.new(nil, employee) }

  let(:employee) { double("employee") }

  it "requires AttendanceRequest create" do
    expect(employee).to receive(:can?).with(:create, AttendanceRequest).twice.and_return(true)

    expect(policy.new?).to be(true)
    expect(policy.create?).to be(true)
  end

  it "denies employees without AttendanceRequest create" do
    expect(employee).to receive(:can?).with(:create, AttendanceRequest).twice.and_return(false)

    expect(policy.new?).to be(false)
    expect(policy.create?).to be(false)
  end
end
