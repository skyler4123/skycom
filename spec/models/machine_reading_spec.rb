# spec/models/machine_reading_spec.rb
require "rails_helper"

RSpec.describe MachineReading, type: :model do
  describe "table" do
    it "uses machine_readings" do
      expect(described_class.table_name).to eq("machine_readings")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:work_center) }
  end
end
