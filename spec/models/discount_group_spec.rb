require "rails_helper"

RSpec.describe DiscountGroup do
  let(:company) { create(:company) }

  describe "validations" do
    it "requires name scoped to company" do
      group = Seed::DiscountGroupService.create(company: company, name: "Summer", prefix: "SUM")
      expect(group).to be_persisted

      expect {
        Seed::DiscountGroupService.create(company: company, name: "Summer", prefix: "X")
      }.to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
    end

    it "requires amount_cents for fixed_amount and percentage for percentage" do
      fixed = DiscountGroup.new(company: company, name: "F", discount_type: :fixed_amount, percentage: nil, amount_cents: nil)
      expect(fixed).not_to be_valid
      fixed.amount_cents = 500
      expect(fixed).to be_valid

      pct = DiscountGroup.new(company: company, name: "P", discount_type: :percentage, amount_cents: nil, percentage: 150)
      expect(pct).not_to be_valid
      pct.percentage = 10
      expect(pct).to be_valid
    end

    it "rejects end_at before start_at" do
      group = Seed::DiscountGroupService.new(company: company, name: "Window", prefix: "W",
        discount_type: :fixed_amount, amount_cents: 100)
      group.start_at = Time.current
      group.end_at = 1.day.ago
      expect(group).not_to be_valid
    end

    it "normalizes the prefix to uppercase" do
      group = Seed::DiscountGroupService.create(company: company, name: "Case", prefix: "summer")
      expect(group.reload.prefix).to eq("SUMMER")
    end
  end

  describe "#currently_active?" do
    it "is true only for active campaigns inside the window" do
      group = Seed::DiscountGroupService.create(company: company, name: "Live", prefix: "L",
        discount_type: :fixed_amount, amount_cents: 100, campaign_status: :active)
      expect(group).to be_currently_active

      group.update!(campaign_status: :paused)
      expect(group).not_to be_currently_active
    end

    it "is false outside the start/end window" do
      group = Seed::DiscountGroupService.create(company: company, name: "Past", prefix: "PAST",
        discount_type: :fixed_amount, amount_cents: 100, campaign_status: :active,
        start_at: 10.days.ago, end_at: 5.days.ago)
      expect(group).not_to be_currently_active
    end
  end

  describe "#adjust_spent!" do
    it "exhausts the group at the budget cap and reactivates on refund" do
      group = Seed::DiscountGroupService.create(company: company, name: "Capped", prefix: "C",
        discount_type: :fixed_amount, amount_cents: 100, total_budget_cents: 150,
        campaign_status: :active)

      group.adjust_spent!(100)
      expect(group.reload.current_spent_cents).to eq(100)
      expect(group).to be_campaign_status_active

      group.adjust_spent!(100)
      expect(group.reload.current_spent_cents).to eq(200)
      expect(group).to be_campaign_status_exhausted

      group.adjust_spent!(-100)
      expect(group.reload.current_spent_cents).to eq(100)
      expect(group).to be_campaign_status_active
    end
  end
end
