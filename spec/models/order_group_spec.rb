# spec/models/order_group_spec.rb
require 'rails_helper'

RSpec.describe OrderGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:customer) }
    it { should have_many(:employee_order_group_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_order_group_appointments) }
    it { should have_many(:order_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:order_group_tag_appointments) }
  end
  it_behaves_like "property_mapping concern", OrderGroup
end
