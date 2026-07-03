require 'rails_helper'

RSpec.describe AttendanceRecord, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
    it { should belong_to(:scheduled_shift).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:check_in_at) }
  end
end
