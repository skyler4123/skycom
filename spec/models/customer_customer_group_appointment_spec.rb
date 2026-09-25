# spec/models/customer_customer_group_appointment_spec.rb
require "rails_helper"

RSpec.describe CustomerCustomerGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:customer_group) }
  end
end
