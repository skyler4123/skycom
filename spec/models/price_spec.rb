# spec/models/price_spec.rb
require 'rails_helper'

RSpec.describe Price, type: :model do
  describe "associations" do
    it { should have_many(:period_prices).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:currency_code) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:currency_code) }
  end
end