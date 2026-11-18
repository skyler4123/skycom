# spec/models/applicant_spec.rb
require "rails_helper"

RSpec.describe Applicant, type: :model do
  describe "table" do
    it "uses applicants" do
      expect(described_class.table_name).to eq("applicants")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:job_opening) }
    it { should belong_to(:resume_stored_file).class_name("StoredFile").optional }
    it { should belong_to(:workflow_step).optional }
    it { should have_many(:applicant_interviews).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:stage).with_prefix(true).with_values(applied: 0, screening: 1, interview: 2, offer: 3, hired: 4, rejected: 5, withdrawn: 6) }
  end
end
