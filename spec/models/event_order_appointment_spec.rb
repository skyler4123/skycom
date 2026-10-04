require "rails_helper"

RSpec.describe EventOrderAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:event) }
    it { should belong_to(:order) }
  end

  describe "derives company from the event" do
    it "sets company_id when not given" do
      event = create(:event)
      branch = create(:branch, company: event.company)
      customer = create(:customer, company: event.company)
      order = create(:order, company: event.company, branch: branch, customer: customer, workflow_status: :pending)

      appointment = described_class.create!(event: event, order: order)

      expect(appointment.company_id).to eq(event.company_id)
    end
  end
end
