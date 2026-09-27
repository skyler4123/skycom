# spec/models/employee_group_role_appointment_spec.rb
require 'rails_helper'

RSpec.describe EmployeeGroupRoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee_group).touch(true) }
    it { should belong_to(:role) }
  end

  describe "owner immutability" do
    let!(:company) { create(:company) }
    let!(:role) { create(:role, company: company) }
    let!(:employee_group) { create(:employee_group, company: company) }
    let!(:owner_appointment) do
      EmployeeGroupRoleAppointment.create!(
        company: company, employee_group: employee_group, role: role, business_type: :owner
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
