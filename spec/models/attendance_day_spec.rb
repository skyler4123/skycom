require 'rails_helper'

RSpec.describe AttendanceDay, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it { should validate_presence_of(:attendance_date) }
  end
end
