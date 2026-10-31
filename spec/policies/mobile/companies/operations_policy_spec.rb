# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mobile::Companies::OperationsPolicy do
  subject(:policy) { described_class.new(nil, employee) }

  let(:employee) { double("employee") }

  it "requires Page read" do
    expect(employee).to receive(:can?).with(:read, Page).and_return(true)

    expect(policy.index?).to be(true)
  end

  it "denies employees without Page read" do
    expect(employee).to receive(:can?).with(:read, Page).and_return(false)

    expect(policy.index?).to be(false)
  end
end
