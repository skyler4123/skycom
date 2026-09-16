# spec/models/system_spec.rb
require 'rails_helper'

RSpec.describe System, type: :model do
  subject { System.new(code: "system_test") }

  describe "validations" do
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end

  describe "enums" do
    it { should define_enum_for(:country).with_values(System::SYSTEM_COUNTRY_CODES).with_prefix(:country) }
    it { should define_enum_for(:currency).with_values(CURRENCIE_CODES).with_prefix(:currency) }
  end

  describe "geographic records" do
    it "allows multiple System records with distinct codes (global, US, VN)" do
      expect {
        System.create!(code: "system_global", name: "Global System", country: :global, currency: :usd)
        System.create!(code: "system_us", name: "US System", country: :us, currency: :usd)
        System.create!(code: "system_vn", name: "VN System", country: :vn, currency: :vnd)
      }.not_to raise_error
      expect(System.where(code: %w[system_global system_us system_vn]).count).to eq(3)
      expect(System.find_by(code: "system_global")).to be_country_global
    end

    it "rejects duplicate codes" do
      System.create!(code: "system_us", name: "US System", country: :us, currency: :usd)
      duplicate = System.new(code: "system_us", name: "US System Copy")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to be_present
    end
  end

  describe "system company" do
    around do |example|
      Company.skip_init = false
      example.run
    ensure
      Company.skip_init = true
    end

    it "creates a dedicated super_admin user and a system company on create" do
      system = System.create!(code: "system_spec", name: "Spec System", country: :us, currency: :usd)

      user = User.find_by(email: "system_spec@system.com")
      expect(user).to be_present
      expect(user.system_role).to eq("super_admin")

      company = system.company
      expect(company).to be_present
      expect(company.user).to eq(user)
      expect(company).to be_business_type_system
      expect(company.name).to eq("Spec System")
      expect(company).to be_country_us
      expect(company).to be_currency_usd
      expect(company).to be_system_company
      expect(Company.system_companies).to include(company)

      # Owner records only — no retail/business seeding
      expect(company.employees.where(business_type: :owner)).to exist
      expect(company.company_wallet).to be_present
      expect(company.settings.where(code: Company::DEFAULT_SETTINGS_CODE)).to exist
      expect(company.categories.where(resource_name: "products")).to be_empty
    end

    it "maps system country/currency to company country/currency" do
      global = System.create!(code: "system_global_spec", name: "Global Spec", country: :global, currency: :usd)
      vn = System.create!(code: "system_vn_spec", name: "VN Spec", country: :vn, currency: :vnd)

      expect(global.company).to be_country_us
      expect(global.company).to be_currency_usd
      expect(vn.company).to be_country_vn
      expect(vn.company).to be_currency_vnd
    end

    it "does not recreate the company when ensure_company! runs again" do
      system = System.create!(code: "system_idem_spec", name: "Idem Spec", country: :us, currency: :usd)
      company_id = system.company_id

      system.ensure_company!

      expect(system.reload.company_id).to eq(company_id)
    end

    it "recreates the company when the company is wiped (seed heal path)" do
      system = System.create!(code: "system_heal_spec", name: "Heal Spec", country: :us, currency: :usd)
      old_company_id = system.company_id

      # Mirror Seed::ApplicationService: referential integrity disabled, rows deleted
      ActiveRecord::Base.connection.disable_referential_integrity do
        Company.unscoped.where(id: old_company_id).delete_all
      end

      expect(system.reload.company).to be_nil

      system.ensure_company!

      expect(system.reload.company).to be_present
      expect(system.company_id).not_to eq(old_company_id)
      expect(system.company.user).to eq(User.find_by(email: "system_heal_spec@system.com"))
    end
  end
end
