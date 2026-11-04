# frozen_string_literal: true

require "rails_helper"

# The mobile Operations tab lists Operation records, so every employee role needs
# Operation read. Owner has the all-access policy and is excluded from the matrix.
RSpec.describe "Mobile Operation read seeding" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  %i[retail hospital hotel].each do |business_type|
    it "grants Operation read to every non-owner role for #{business_type}" do
      company = create(:company, business_type: business_type)
      policy = company.policies.find_by!(resource: "Operation", action: "read")

      company.roles.where.not(name: OWNER_BUSINESS_TYPE).find_each do |role|
        appointment = PolicyRoleAppointment.find_by(company: company, policy: policy, role: role)

        expect(appointment&.workflow_status).to eq("active"),
          "expected #{business_type} #{role.name} to hold Operation read"
      end
    end
  end
end
