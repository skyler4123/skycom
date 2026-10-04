require "rails_helper"

RSpec.describe BranchEventAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
    it { should belong_to(:event) }
  end

  describe "derives company from the branch" do
    it "sets company_id when not given" do
      branch = create(:branch)
      event = create(:event, company: branch.company)

      appointment = described_class.create!(branch: branch, event: event)

      expect(appointment.company_id).to eq(branch.company_id)
    end
  end
end
