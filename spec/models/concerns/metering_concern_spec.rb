# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeteringConcern do
  describe "class methods" do
    it "stores the metered resource key as a symbol" do
      expect(Order.metered_resource_key).to eq(:orders)
    end

    it "returns nil for models without metered_as declaration" do
      expect(Company.respond_to?(:metered_resource_key, true)).to be false
    end
  end

  describe "increment_usage_counter" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:customer) { create(:customer, company: company, branch: branch) }

    it "increments Redis counter when order is created" do
      date_str = Date.current.strftime("%Y%m%d")
      redis_key = "skycom:company:#{company.id}:orders:#{date_str}"

      create(:order, company: company, branch: branch, customer: customer)
      expect(Kredis.redis.exists?(redis_key)).to be(true)
      expect(Kredis.redis.get(redis_key).to_i).to be > 0
    end
  end
end
