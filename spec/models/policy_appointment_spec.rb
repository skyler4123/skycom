# spec/models/policy_appointment_spec.rb
require 'rails_helper'

RSpec.describe PolicyAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:policy) }
    it { should belong_to(:appoint_to) }
  end

  describe "enums" do
    it { should define_enum_for(:workflow_status).with_values(inactive: 0, active: 1) }
  end
end