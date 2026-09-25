# spec/models/customer_group_service_appointment_spec.rb
require "rails_helper"

RSpec.describe CustomerGroupServiceAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer_group) }
    it { should belong_to(:service) }
  end
end
