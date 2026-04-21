# spec/models/payment_spec.rb
require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:invoice) }
  end

  describe "validations" do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:currency_code) }
    it { should validate_presence_of(:payment_method) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
  end
end