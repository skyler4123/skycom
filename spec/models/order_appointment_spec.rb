# spec/models/order_appointment_spec.rb
require 'rails_helper'

RSpec.describe OrderAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:order) }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
  end
end