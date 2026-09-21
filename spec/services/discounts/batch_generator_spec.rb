require "rails_helper"

RSpec.describe Discounts::BatchGenerator do
  let(:company) { create(:company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Batch", prefix: "SUMMER26",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end

  describe "#generate" do
    it "bulk-inserts the requested quantity with the prefixed format" do
      expect {
        result = described_class.call(discount_group: group, quantity: 25)
        expect(result[:success]).to be(true)
        expect(result[:generated]).to eq(25)
      }.to change(Discount, :count).by(25)

      codes = group.discounts.pluck(:code)
      expect(codes).to all(match(/\ASUMMER26-[A-Z0-9]{8}\z/))
      expect(codes.uniq.size).to eq(25)
      expect(group.discounts.where(status: :unused).count).to eq(25)
    end

    it "avoids collisions with pre-existing codes in the same company" do
      existing = Seed::DiscountService.create(company: company, discount_group: group, code: "SUMMER26-AAAAAAAA")

      result = described_class.call(discount_group: group, quantity: 10)

      expect(result[:success]).to be(true)
      expect(group.discounts.where(code: "SUMMER26-AAAAAAAA").count).to eq(1)
      expect(group.discounts.where.not(id: existing.id).pluck(:code)).not_to include("SUMMER26-AAAAAAAA")
    end

    it "keeps batches from different groups in the same company collision-free" do
      other = Seed::DiscountGroupService.create(company: company, name: "Other", prefix: "OTHER",
        discount_type: :fixed_amount, amount_cents: 100, campaign_status: :active)

      described_class.call(discount_group: group, quantity: 10)
      result = described_class.call(discount_group: other, quantity: 10)

      expect(result[:success]).to be(true)
      expect(company.discounts.count).to eq(20)
      expect(company.discounts.distinct.count(:code)).to eq(20)
    end

    it "generates unprefixed codes when the group has no prefix" do
      bare = Seed::DiscountGroupService.create(company: company, name: "Bare", prefix: nil,
        discount_type: :percentage, percentage: 5, campaign_status: :active)

      described_class.call(discount_group: bare, quantity: 3)

      expect(bare.discounts.pluck(:code)).to all(match(/\A[A-Z0-9]{8}\z/))
    end

    it "rejects out-of-bounds quantities" do
      [ 0, -1, 1001 ].each do |quantity|
        result = described_class.call(discount_group: group, quantity: quantity)
        expect(result).to eq({ success: false, errors: [ "Quantity must be between 1 and 1000" ] })
      end
      expect(Discount.count).to eq(0)
    end

    it "rejects prefixes too long for the code length" do
      group.update_columns(prefix: "X" * 250) # bypass normalizes to force the overflow case
      result = described_class.call(discount_group: group, quantity: 5)
      expect(result).to eq({ success: false, errors: [ "Prefix is too long for the requested code length" ] })
      expect(Discount.count).to eq(0)
    end
  end
end
