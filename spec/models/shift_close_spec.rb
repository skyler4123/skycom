# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShiftClose, type: :model do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }

  it "stores one close per branch and business date" do
    create(:shift_close, company: company, branch: branch, business_date: Date.current)
    duplicate = build(:shift_close, company: company, branch: branch, business_date: Date.current)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:business_date]).to be_present
  end

  it "requires a note when the variance is not zero" do
    close = build(:shift_close, company: company, branch: branch, variance_cents: -500, note: nil)

    expect(close).not_to be_valid
    expect(close.errors[:note]).to include("is required when the variance is not zero")
  end

  it "accepts a non-zero variance with a note" do
    close = build(:shift_close, company: company, branch: branch, variance_cents: -500, note: "Two bills short")

    expect(close).to be_valid
  end

  it "rejects negative money figures" do
    close = build(:shift_close, company: company, branch: branch, counted_cash_cents: -1)

    expect(close).not_to be_valid
    expect(close.errors[:counted_cash_cents]).to be_present
  end
end
