# spec/models/document_group_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe DocumentGroupEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:document_group) }
    it { should belong_to(:employee) }
  end
end
