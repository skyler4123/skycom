require "rails_helper"

RSpec.describe "retail init seeds the Event domain" do
  # rails_helper disables company init (Company.skip_init) — enable it here
  # so the factory-built company runs Seed::RetailInitService.
  around do |example|
    Company.skip_init = false
    example.run
    Company.skip_init = true
  end

  let(:company) { create(:company, business_type: :retail) }

  it "creates events categories with table configs" do
    names = company.categories.where(resource_name: "events").order(:name).pluck(:name)

    expect(names).to include("Procedure Booking", "Room Stay", "Table Reservation")
  end

  it "creates one event config per events category" do
    categories = company.categories.where(resource_name: "events")

    expect(categories.count).to be > 0
    categories.each do |category|
      config = EventConfig.find_by(company: company, category: category)
      expect(config).to be_present
    end
  end

  it "grants managers full event permissions" do
    manager = Role.find_by!(name: "Manager", company: company)

    %w[Event EventConfig].each do |resource|
      %w[create read update delete].each do |action|
        policy = Policy.find_by!(company: company, resource: resource, action: action)
        appointment = PolicyRoleAppointment.find_by!(company: company, policy: policy, role: manager)
        expect(appointment.workflow_status).to eq("active"), "expected Manager #{action} #{resource} active"
      end
    end
  end
end
