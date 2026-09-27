# spec/models/employee_product_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeProductAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:product) }
  end
end
