require "rails_helper"

RSpec.describe EventStockAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:event) }
    it { should belong_to(:stock) }
  end

  describe "validations" do
    it { should validate_presence_of(:quantity) }
  end

  describe "derives company from the event" do
    it "sets company_id when not given" do
      event = create(:event)
      stock = create(:stock, company: event.company)

      appointment = described_class.create!(event: event, stock: stock, quantity: 2)

      expect(appointment.company_id).to eq(event.company_id)
    end
  end

  describe "never moves inventory" do
    it "leaves quantity and pending untouched" do
      event = create(:event)
      stock = create(:stock, company: event.company)
      before = [ stock.reload.quantity, stock.pending ]

      described_class.create!(event: event, stock: stock, quantity: 3)

      expect([ stock.reload.quantity, stock.pending ]).to eq(before)
    end
  end
end
