# spec/models/service_service_group_appointment_spec.rb
require "rails_helper"

RSpec.describe ServiceServiceGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:service) }
    it { should belong_to(:service_group) }
  end
end
