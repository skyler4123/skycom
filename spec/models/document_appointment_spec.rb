# spec/models/document_appointment_spec.rb
require 'rails_helper'

RSpec.describe DocumentAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:document) }
    it { should belong_to(:appoint_from) }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_for) }
    it { should belong_to(:appoint_by) }
  end
end
