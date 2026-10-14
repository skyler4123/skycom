# spec/models/employee_owner_role_spec.rb
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe "#owner_role?" do
    let!(:company) { create(:company) }
    let!(:owner_employee) { company.employees.find_by(business_type: OWNER_BUSINESS_TYPE) }
    let!(:regular_employee) { create(:employee, company: company, business_type: :full_time) }

    it "returns true for owner employee and caches in ram_cache" do
      expect(owner_employee.owner_role?).to be(true)
      expect(Rails.ram_cache.read("#{owner_employee.cache_key_with_version}/owner_role")).to be(true)
    end

    it "returns false for non-owner employee and caches in ram_cache" do
      expect(regular_employee.owner_role?).to be(false)
      expect(Rails.ram_cache.read("#{regular_employee.cache_key_with_version}/owner_role")).to be(false)
    end

    it "does not write owner_role key to local_cache" do
      owner_employee.owner_role?
      expect(Rails.local_cache.read("#{owner_employee.cache_key_with_version}/owner_role")).to be_nil
    end

    it "evicts ram_cache entry on clear_permissions_cache" do
      owner_employee.owner_role?
      expect(Rails.ram_cache.read("#{owner_employee.cache_key_with_version}/owner_role")).to be(true)
      owner_employee.clear_permissions_cache
      expect(Rails.ram_cache.read("#{owner_employee.cache_key_with_version}/owner_role")).to be_nil
    end
  end
end
