# spec/models/stock_spec.rb
require 'rails_helper'

RSpec.describe Stock, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:warehouse) }
    it { should belong_to(:category).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end