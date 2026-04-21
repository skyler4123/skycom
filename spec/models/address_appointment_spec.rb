# spec/models/address_appointment_spec.rb
require 'rails_helper'

RSpec.describe AddressAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:address) }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
  end
end
