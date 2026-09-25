require "rails_helper"

RSpec.describe OrderSubscriptionPlanAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:order) }
    it { should belong_to(:subscription_plan) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_price).is_greater_than_or_equal_to(0).allow_nil }
  end
end
