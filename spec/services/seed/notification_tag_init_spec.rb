require "rails_helper"

RSpec.describe "init seeds system notification tags" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  shared_examples "a notification tag init" do |business_type, init_roles|
    let(:company) { create(:company, business_type: business_type) }

    it "creates fixed Owner and All Employees system tags with descriptions" do
      owner = NotificationTag.find_by(company: company, name: "Owner")
      all_employees = NotificationTag.find_by(company: company, name: "All Employees")

      expect(owner).to be_present
      expect(owner.system?).to be(true)
      expect(owner.description).to be_present

      expect(all_employees).to be_present
      expect(all_employees.system?).to be(true)
      expect(all_employees.description).to be_present
    end

    it "creates one system tag per init role with description" do
      init_roles.each do |role_name|
        tag = NotificationTag.find_by(company: company, name: "All #{role_name}")
        expect(tag).to be_present, "expected tag All #{role_name}"
        expect(tag.system?).to be(true), "expected All #{role_name} to be system"
        expect(tag.description).to be_present
      end
    end

    it "does not create a tag for the owner role" do
      expect(NotificationTag.find_by(company: company, name: "All owner")).to be_nil
    end

    it "is idempotent" do
      expect {
        Seed::NotificationTagService.create_defaults!(company: company)
      }.not_to change { NotificationTag.where(company: company).count }
    end
  end

  describe "retail init" do
    include_examples "a notification tag init", :retail,
      %w[Manager Cashier Seller Security Admin Doctor Therapist Consultant]
  end

  describe "hospital init" do
    include_examples "a notification tag init", :hospital,
      %w[Receptionist Dentist DentalAssistant Hygienist Manager Admin]
  end

  describe "hotel init" do
    include_examples "a notification tag init", :hotel,
      %w[Receptionist Housekeeper Concierge Chef Manager Admin]
  end
end
