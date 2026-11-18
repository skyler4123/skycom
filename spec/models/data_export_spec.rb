# spec/models/data_export_spec.rb
require "rails_helper"

RSpec.describe DataExport, type: :model do
  describe "table" do
    it "uses data_exports" do
      expect(described_class.table_name).to eq("data_exports")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:requested_by_employee).class_name("Employee").optional }
    it { should belong_to(:stored_file).optional }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(queued: 0, running: 1, completed: 2, failed: 3) }
  end
end
