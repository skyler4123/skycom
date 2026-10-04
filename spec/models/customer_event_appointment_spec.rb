require "rails_helper"

RSpec.describe CustomerEventAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:event) }
  end

  describe "derives company from the customer" do
    it "sets company_id when not given" do
      customer = create(:customer)
      event = create(:event, company: customer.company)

      appointment = described_class.create!(customer: customer, event: event)

      expect(appointment.company_id).to eq(customer.company_id)
    end
  end
end
