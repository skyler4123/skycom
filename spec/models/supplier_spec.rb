# spec/models/supplier_spec.rb
require 'rails_helper'

RSpec.describe Supplier, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
  end

  describe "validations" do
    let!(:company) { create(:company) }
    let!(:supplier) { create(:supplier, company: company) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:business_type) }
    it { should validate_uniqueness_of(:name).scoped_to(:company_id) }
    it { should validate_uniqueness_of(:code).scoped_to(:company_id) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(manufacturer: 0, distributor: 1, wholesaler: 2, service_provider: 3) }
  end
  it_behaves_like "property_mapping concern", Supplier
end
