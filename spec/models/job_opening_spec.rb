# spec/models/job_opening_spec.rb
require "rails_helper"

RSpec.describe JobOpening, type: :model do
  describe "table" do
    it "uses job_openings" do
      expect(described_class.table_name).to eq("job_openings")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:department).optional }
    it { should have_many(:applicants).dependent(:restrict_with_error) }
    it { should have_many(:employees).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_numericality_of(:openings_count).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, pending: 1, confirmed: 2, in_progress: 3, completed: 4, paid: 5, cancelled: 6, refunded: 7, failed: 8, initiated: 9, received: 10, shipped: 11) }
  end
end
