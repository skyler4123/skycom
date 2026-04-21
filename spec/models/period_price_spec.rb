# spec/models/period_price_spec.rb
require 'rails_helper'

RSpec.describe PeriodPrice, type: :model do
  describe "associations" do
    it { should belong_to(:period) }
    it { should belong_to(:price) }
  end
end
