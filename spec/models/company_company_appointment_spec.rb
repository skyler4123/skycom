# spec/models/company_company_appointment_spec.rb
require "rails_helper"

RSpec.describe CompanyCompanyAppointment, type: :model do
  describe "table" do
    it "uses company_company_appointments" do
      expect(described_class.table_name).to eq("company_company_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:parent_company).class_name("Company") }
    it { should belong_to(:child_company).class_name("Company") }
  end

  describe "validations" do
    it { should validate_numericality_of(:ownership_bp).only_integer.is_greater_than(0).is_less_than_or_equal_to(10000) }
    it "declares child_company_id uniqueness scoped to parent_company_id" do
      validator = described_class.validators_on(:child_company_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[parent_company_id])
    end
  end

describe "ownership" do
  it "refuses a company that owns itself" do
    id = SecureRandom.uuid
    link = described_class.new(parent_company_id: id, child_company_id: id)
    link.valid?

    expect(link.errors[:child_company]).to include("cannot be the same company")
  end
end
end
