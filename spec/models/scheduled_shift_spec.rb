require 'rails_helper'

RSpec.describe ScheduledShift, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
    it { should belong_to(:employee) }
    it { should belong_to(:shift_template).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:work_date) }
    it { should validate_presence_of(:expected_start_at) }
    it { should validate_presence_of(:expected_end_at) }
    it { should validate_presence_of(:status) }
  end
end
