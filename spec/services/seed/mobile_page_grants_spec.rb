# frozen_string_literal: true

require "rails_helper"

# The mobile Operations tab lists Page records, so every employee role needs
# Page read. Owner has the all-access policy and is excluded from the matrix.
RSpec.describe "Mobile Page read seeding" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  %i[retail hospital hotel].each do |business_type|
    it "grants Page read to every non-owner role for #{business_type}" do
      company = create(:company, business_type: business_type)
      policy = company.policies.find_by!(resource: "Page", action: "read")

      company.roles.where.not(name: OWNER_BUSINESS_TYPE).find_each do |role|
        appointment = PolicyRoleAppointment.find_by(company: company, policy: policy, role: role)

        expect(appointment&.workflow_status).to eq("active"),
          "expected #{business_type} #{role.name} to hold Page read"
      end
    end
  end
end
