# spec/models/customer_group_role_appointment_spec.rb
require 'rails_helper'

RSpec.describe CustomerGroupRoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer_group).touch(true) }
    it { should belong_to(:role) }
  end

  describe "owner immutability" do
    let!(:company) { create(:company) }
    let!(:role) { create(:role, company: company) }
    let!(:customer_group) { Seed::CustomerGroupService.create(company: company) }
    let!(:owner_appointment) do
      CustomerGroupRoleAppointment.create!(
        company: company, customer_group: customer_group, role: role, business_type: :owner
      )
    end

    it "blocks update of the owner appointment" do
      expect { owner_appointment.update!(description: "changed") }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "blocks destroy of the owner appointment" do
      expect { owner_appointment.destroy! }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
