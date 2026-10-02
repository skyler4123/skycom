require "rails_helper"

RSpec.describe EventServiceAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:event) }
    it { should belong_to(:service) }
  end

  describe "derives company from the event" do
    it "sets company_id when not given" do
      company = create(:company)
      branch = create(:branch, company: company)
      service = Seed::ServiceService.create(company: company, branch: branch)
      event = create(:event, company: company)

      appointment = described_class.create!(event: event, service: service)

      expect(appointment.company_id).to eq(event.company_id)
    end
  end
end
