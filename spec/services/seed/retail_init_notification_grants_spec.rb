require "rails_helper"

RSpec.describe "RetailInitService notification grants" do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }

  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  it "grants every role read access to notifications" do
    %w[Admin Manager Cashier Seller Security].each do |role_name|
      role = company.roles.find_by(name: role_name)
      next if role.nil?

      policy = company.policies.find_by(resource: "Notification", action: "read")
      appt = PolicyRoleAppointment.find_by(company: company, policy: policy, role: role)
      expect(appt&.workflow_status).to eq("active"), "expected #{role_name} to hold read Notification"
    end
  end
end
