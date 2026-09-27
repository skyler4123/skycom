# spec/models/customer_service_appointment_spec.rb
require "rails_helper"

RSpec.describe CustomerServiceAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:service) }
  end
end
