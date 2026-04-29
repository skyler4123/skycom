# spec/models/warehouse_spec.rb
require 'rails_helper'

RSpec.describe Warehouse, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:category).optional }
    it { should belong_to(:address).optional }
    it { should have_many(:stocks) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end