# spec/models/subscription_group_spec.rb
require 'rails_helper'

RSpec.describe SubscriptionGroup, type: :model do
  describe "associations" do
    it { should have_many(:subscription_group_subscription_plan_appointments).dependent(:restrict_with_error) }
    it { should have_many(:subscription_plans).through(:subscription_group_subscription_plan_appointments) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
  end
end
