# spec/models/quality_inspection_spec.rb
require "rails_helper"

RSpec.describe QualityInspection, type: :model do
  describe "table" do
    it "uses quality_inspections" do
      expect(described_class.table_name).to eq("quality_inspections")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:subject) }
    it { should belong_to(:inspector_employee).class_name("Employee").optional }
    it { should have_many(:quality_checks).dependent(:destroy) }
    it { should have_many(:non_conformances).dependent(:nullify) }
  end

  describe "enums" do
    it { should define_enum_for(:inspection_type).with_prefix(true).with_values(receiving: 0, in_process: 1, final: 2) }
  end
end
