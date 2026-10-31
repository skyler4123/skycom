# frozen_string_literal: true

require "rails_helper"

RSpec.describe Companies::AnalyticsPolicy do
  subject(:policy) { described_class.new(nil, record) }

  let(:record) { double("employee") }

  it "requires Invoice read" do
    expect(record).to receive(:can?).with(:read, Invoice).and_return(true)

    expect(policy.index?).to be(true)
  end

  it "denies employees without Invoice read" do
    expect(record).to receive(:can?).with(:read, Invoice).and_return(false)

    expect(policy.index?).to be(false)
  end
end
