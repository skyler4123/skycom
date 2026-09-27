# spec/models/document_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe DocumentEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:document) }
    it { should belong_to(:employee) }
  end
end
