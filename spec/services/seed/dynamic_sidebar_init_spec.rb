require "rails_helper"

RSpec.describe "init seeds the dynamic sidebar Setting" do
  # rails_helper disables company init (Company.skip_init) — enable it here
  # so the factory-built company runs the business-type init service.
  around do |example|
    Company.skip_init = false
    example.run
    Company.skip_init = true
  end

  shared_examples "a dynamic sidebar init" do |business_type|
    let(:company) { create(:company, business_type: business_type) }

    it "creates one empty dynamic sidebar Setting at the company level" do
      record = Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE)
      expect(record).to be_present
      expect(record.appoint_to).to eq(company)
      expect(record.sidebar_groups).to eq([])
    end

    it "grants Admin and Manager full Setting permissions" do
      %w[Admin Manager].each do |role_name|
        role = Role.find_by!(name: role_name, company: company)
        %w[create read update delete].each do |action|
          policy = Policy.find_by!(company: company, resource: "Setting", action: action)
          appointment = PolicyRoleAppointment.find_by!(company: company, policy: policy, role: role)
          expect(appointment.workflow_status).to eq("active"), "expected #{role_name} #{action} Setting active"
        end
      end
    end
  end

  describe "retail init" do
    include_examples "a dynamic sidebar init", :retail
  end

  describe "hospital init" do
    include_examples "a dynamic sidebar init", :hospital
  end

  describe "hotel init" do
    include_examples "a dynamic sidebar init", :hotel
  end
end
