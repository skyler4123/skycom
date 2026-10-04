require "rails_helper"

RSpec.describe EventFacilityAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:event) }
    it { should belong_to(:facility) }
  end

  describe "derives company from the event" do
    it "sets company_id when not given" do
      event = create(:event)
      facility = create(:facility, company: event.company)

      appointment = described_class.create!(event: event, facility: facility)

      expect(appointment.company_id).to eq(event.company_id)
    end
  end
end
