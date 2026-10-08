require "rails_helper"

RSpec.describe "RetailInitService AttendanceRequest grants" do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }

  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  def grant_status(role_name, action)
    role = company.roles.find_by(name: role_name)
    return nil if role.nil?

    policy = company.policies.find_by(resource: "AttendanceRequest", action: action)
    return nil if policy.nil?

    PolicyRoleAppointment.find_by(company: company, policy: policy, role: role)&.workflow_status
  end

  it "grants Admin and Manager full CRUD on AttendanceRequest" do
    %w[Admin Manager].each do |role_name|
      %w[create read update delete].each do |action|
        expect(grant_status(role_name, action)).to eq("active"), "expected #{role_name} to hold #{action} AttendanceRequest"
      end
    end
  end

  it "grants Cashier and Seller create/read only on AttendanceRequest" do
    %w[Cashier Seller].each do |role_name|
      expect(grant_status(role_name, "create")).to eq("active")
      expect(grant_status(role_name, "read")).to eq("active")
      expect(grant_status(role_name, "update")).to eq("inactive")
    end
  end
end
