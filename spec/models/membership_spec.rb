require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe "associations" do
    it { should have_many(:customer_membership_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_membership_appointments) }
  end
  it_behaves_like "property_mapping concern", Membership
end
