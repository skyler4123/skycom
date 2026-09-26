require "rails_helper"

RSpec.describe OrderServiceAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:order) }
    it { should belong_to(:service) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_price).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "derives company from the order" do
    it "sets company_id when not given" do
      company = create(:company)
      branch = create(:branch, company: company)
      customer = create(:customer, company: company)
      order = create(:order, company: company, branch: branch, customer: customer)
      # NOTE: factory :service is broken (bare `association :branch` override),
      # so build via the seed service directly.
      service = Seed::ServiceService.create(company: company, branch: branch)

      appointment = described_class.create!(order: order, service: service, quantity: 1, unit_price: 50.0)

      expect(appointment.company_id).to eq(order.company_id)
    end
  end
end
