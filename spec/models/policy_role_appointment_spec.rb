# spec/models/policy_role_appointment_spec.rb
require 'rails_helper'

RSpec.describe PolicyRoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:policy) }
    it { should belong_to(:role).touch(true) }
  end

  describe "enums" do
    it { should define_enum_for(:workflow_status).with_values(inactive: 0, active: 1) }
  end

  describe "owner immutability" do
    let!(:company) { create(:company) }
    let(:owner_appointment) do
      PolicyRoleAppointment.find_by(company: company, business_type: :owner)
    end

    it "blocks update of the owner appointment" do
      expect(owner_appointment).to be_present
      expect { owner_appointment.update!(description: "changed") }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "blocks destroy of the owner appointment" do
      expect { owner_appointment.destroy! }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
