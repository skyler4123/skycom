# spec/models/exam_appointment_spec.rb
require 'rails_helper'

RSpec.describe ExamAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:exam) }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
  end
end