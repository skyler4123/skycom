require "rails_helper"

RSpec.describe "init seeds the sidebar CompanySetting" do
  # rails_helper disables company init (Company.skip_init) — enable it here
  # so the factory-built company runs the business-type init service.
  around do |example|
    Company.skip_init = false
    example.run
    Company.skip_init = true
  end

  shared_examples "a sidebar setting init" do |business_type|
    let(:company) { create(:company, business_type: business_type) }

    it "creates one empty active sidebar CompanySetting" do
      record = CompanySetting.find_by(company: company, business_type: :sidebar_groups, workflow_status: :active)
      expect(record).to be_present
      expect(record.sidebar_groups).to eq([])
    end

    it "grants Admin and Manager full CompanySetting permissions" do
      %w[Admin Manager].each do |role_name|
        role = Role.find_by!(name: role_name, company: company)
        %w[create read update delete].each do |action|
          policy = Policy.find_by!(company: company, resource: "CompanySetting", action: action)
          appointment = PolicyRoleAppointment.find_by!(company: company, policy: policy, role: role)
          expect(appointment.workflow_status).to eq("active"), "expected #{role_name} #{action} CompanySetting active"
        end
      end
    end
  end

  describe "retail init" do
    include_examples "a sidebar setting init", :retail
  end

  describe "hospital init" do
    include_examples "a sidebar setting init", :hospital
  end

  describe "hotel init" do
    include_examples "a sidebar setting init", :hotel
  end
end
