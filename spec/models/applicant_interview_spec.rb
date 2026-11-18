# spec/models/applicant_interview_spec.rb
require "rails_helper"

RSpec.describe ApplicantInterview, type: :model do
  describe "table" do
    it "uses applicant_interviews" do
      expect(described_class.table_name).to eq("applicant_interviews")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:applicant) }
    it { should belong_to(:employee).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:scheduled_at) }
  end

  describe "enums" do
    it { should define_enum_for(:outcome).with_prefix(true).with_values(pending: 0, advance: 1, hold: 2, reject: 3) }
  end
end
