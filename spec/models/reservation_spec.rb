require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe "associations" do
    it { should have_many(:customer_reservation_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_reservation_appointments) }
  end
  it_behaves_like "property_mapping concern", Reservation
end
