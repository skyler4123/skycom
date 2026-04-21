# spec/models/subscription_spec.rb
require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:subscription_plan) }
    it { should belong_to(:subscription_group).optional }
    it { should belong_to(:price) }
    it { should belong_to(:period) }
    it { should belong_to(:seller) }
    it { should belong_to(:buyer) }
  end

  describe "enums" do
    it { should define_enum_for(:country_code) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:timezone) }
  end
end