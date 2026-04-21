# spec/models/period_spec.rb
require 'rails_helper'

RSpec.describe Period, type: :model do
  describe "associations" do
    it { should have_many(:period_prices).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:start_at) }
    it { should validate_presence_of(:timezone) }
  end

  describe "enums" do
    it { should define_enum_for(:timezone) }
  end
end
