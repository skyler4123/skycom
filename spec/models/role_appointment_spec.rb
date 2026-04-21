# spec/models/role_appointment_spec.rb
require 'rails_helper'

RSpec.describe RoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:role) }
    it { should belong_to(:appoint_to) }
  end
end
