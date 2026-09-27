require "rails_helper"

RSpec.describe AddressUserAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:address) }
    it { should belong_to(:user) }
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(office: 0, home: 1, billing: 2, shipping: 3) }
  end
end
