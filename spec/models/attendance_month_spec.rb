require 'rails_helper'

RSpec.describe AttendanceMonth, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it { should validate_presence_of(:month) }
  end
end
