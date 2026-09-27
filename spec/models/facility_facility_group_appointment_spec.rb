# spec/models/facility_facility_group_appointment_spec.rb
require "rails_helper"

RSpec.describe FacilityFacilityGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:facility) }
    it { should belong_to(:facility_group) }
  end
end
