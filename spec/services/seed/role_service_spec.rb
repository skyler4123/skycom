# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::RoleService do
  let(:company) { create(:company) }

  describe "generated business type" do
    it "never picks the owner type" do
      company
      allow_any_instance_of(Array).to receive(:sample) { |array| array.first }

      role = described_class.new(company: company, name: "Seller")

      expect(role.business_type).not_to eq(OWNER_BUSINESS_TYPE)
    end
  end
end
