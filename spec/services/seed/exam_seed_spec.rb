# spec/services/seed/exam_seed_spec.rb
require "rails_helper"

RSpec.describe "Exam seed data", type: :model do
  services = {
    retail: Seed::RetailInitService,
    hospital: Seed::HospitalInitService,
    hotel: Seed::HotelInitService
  }

  %i[retail hospital hotel].each do |business_type|
    it "seeds question categories and Question grants for #{business_type}" do
      company = create(:company)
      company.update!(business_type: business_type)
      services.fetch(business_type).call(company: company)

      names = company.categories.where(resource_name: "questions").pluck(:name)
      expect(names).to include("General", "Safety", "Compliance", "Customer Service")
      expect(company.policies.where(resource: "Question").count).to eq(4)

      %w[Manager Admin].each do |role_name|
        role = company.roles.find_by!(name: role_name)
        resources = role.policy_role_appointments.active.includes(:policy).map { |appointment| appointment.policy.resource }
        expect(resources).to include("Question")
      end
    end
  end
end
