require 'rails_helper'

RSpec.describe AttendancePolicy, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
  end

  describe "validations" do
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
  end
end
