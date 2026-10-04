require "rails_helper"

RSpec.describe EventConfig, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
  end

  describe "one config per company and category" do
    it "rejects a second config for the same pair" do
      config = create(:event_config)

      duplicate = build(:event_config, company: config.company, category: config.category)

      expect(duplicate).not_to be_valid
    end
  end

  describe "safe defaults" do
    it "creates no holds and no orders unless opted in" do
      config = described_class.new

      expect(config.create_stock_pending).to be(false)
      expect(config.create_order_on_complete).to be(false)
      expect(config.strict_stock_hold).to be(false)
    end
  end
end
