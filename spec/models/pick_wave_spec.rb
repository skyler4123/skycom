# spec/models/pick_wave_spec.rb
require "rails_helper"

RSpec.describe PickWave, type: :model do
  describe "table" do
    it "uses pick_waves" do
      expect(described_class.table_name).to eq("pick_waves")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:warehouse) }
    it { should belong_to(:created_by_employee).class_name("Employee").optional }
    it { should have_many(:order_pick_wave_appointments).dependent(:destroy) }
    it { should have_many(:orders).through(:order_pick_wave_appointments) }
    it { should have_many(:pick_tasks).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
