# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EmployeeGroup permission seeding" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  it "grants Admin and Manager full EmployeeGroup CRUD for every business type" do
    %i[retail hospital hotel].each do |business_type|
      company = create(:company, business_type: business_type)

      %w[Admin Manager].each do |role_name|
        role = company.roles.find_by!(name: role_name)

        %w[create read update delete].each do |action|
          policy = company.policies.find_by!(resource: "EmployeeGroup", action: action)
          appointment = PolicyRoleAppointment.find_by!(company: company, policy: policy, role: role)
          expect(appointment.workflow_status).to eq("active"),
            "expected #{business_type} #{role_name} to hold #{action} EmployeeGroup"
        end
      end
    end
  end
end
