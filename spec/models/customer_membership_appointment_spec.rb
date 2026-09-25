require "rails_helper"

RSpec.describe CustomerMembershipAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:membership) }
  end
end
