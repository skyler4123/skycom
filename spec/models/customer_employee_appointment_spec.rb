# spec/models/customer_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe CustomerEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:employee) }
  end
end
