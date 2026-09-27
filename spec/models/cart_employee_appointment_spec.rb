require "rails_helper"

RSpec.describe CartEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:cart) }
    it { should belong_to(:employee) }
  end

  describe "derives company from the cart" do
    it "sets company_id when not given" do
      cart = create(:cart)
      employee = create(:employee, company: cart.company)

      appointment = described_class.create!(cart: cart, employee: employee)

      expect(appointment.company_id).to eq(cart.company_id)
    end
  end
end
