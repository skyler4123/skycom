# frozen_string_literal: true

require "rails_helper"

# The enrich services keep their own @employees collection for downstream
# sample-data steps (departments, profiles, events, orders, requests). The owner
# employee must be part of that collection so demo accounts are not empty.
RSpec.describe "Seed enrich services owner inclusion" do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: OWNER_BUSINESS_TYPE) }

  {
    Seed::RetailEnrichService => :@retail,
    Seed::HospitalEnrichService => :@company,
    Seed::HotelEnrichService => :@company
  }.each do |service_class, company_ivar|
    it "#{service_class} adds the owner to the enrich employee set" do
      service = service_class.allocate
      service.instance_variable_set(company_ivar, company)
      service.instance_variable_set(:@branches, [])
      service.instance_variable_set(:@employees, [])
      service.instance_variable_set(:@employee_counter, 0)

      service.send(:create_employees)

      expect(service.instance_variable_get(:@employees)).to include(owner)
    end
  end
end
