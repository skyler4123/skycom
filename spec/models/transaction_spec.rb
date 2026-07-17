# spec/models/transaction_spec.rb
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:invoice) }
    it { should belong_to(:payment_method).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:currency) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:payment_status) }
  end
  it_behaves_like "property_mapping concern", Transaction
end
