require 'rails_helper'

RSpec.describe AttendanceLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it { should validate_presence_of(:log_type) }
    it { should validate_presence_of(:logged_at) }
  end
end
