# spec/models/stock_transfer_spec.rb
require 'rails_helper'

RSpec.describe StockTransfer, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:product) }
    it { should belong_to(:category).optional }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_to).optional }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end