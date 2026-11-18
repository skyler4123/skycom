# spec/models/order_pick_wave_appointment_spec.rb
require "rails_helper"

RSpec.describe OrderPickWaveAppointment, type: :model do
  describe "table" do
    it "uses order_pick_wave_appointments" do
      expect(described_class.table_name).to eq("order_pick_wave_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:order) }
    it { should belong_to(:pick_wave) }
  end

  describe "validations" do
    it "declares order_id uniqueness scoped to pick_wave_id" do
      validator = described_class.validators_on(:order_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[pick_wave_id])
    end
  end
end
