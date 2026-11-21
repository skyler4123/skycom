# spec/models/order_spec.rb
require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:customer).optional }
    it { should belong_to(:employee).class_name("Employee").optional }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:order_product_appointments).dependent(:destroy) }
    it { should have_many(:products).through(:order_product_appointments) }
    it { should have_many(:order_service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:order_service_appointments) }
    it { should have_many(:order_product_group_appointments).dependent(:destroy) }
    it { should have_many(:product_groups).through(:order_product_group_appointments) }
    it { should have_many(:order_service_group_appointments).dependent(:destroy) }
    it { should have_many(:service_groups).through(:order_service_group_appointments) }
    it { should have_many(:order_subscription_plan_appointments).dependent(:destroy) }
    it { should have_many(:subscription_plans).through(:order_subscription_plan_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "accepts an employee from the same company" do
      company = create(:company)
      order = create(:order, company: company, customer: create(:customer, company: company))
      order.employee = create(:employee, company: company)

      expect(order).to be_valid
    end

    it "rejects an employee from another company" do
      company = create(:company)
      order = create(:order, company: company, customer: create(:customer, company: company))
      order.employee = create(:employee)

      expect(order).not_to be_valid
      expect(order.errors[:employee]).to include("must belong to the same company")
    end
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:currency) }
    it { should define_enum_for(:business_type).with_values(online: 0, in_store: 1, phone: 2) }
    it do
      expect(Order.fulfillment_channels).to eq(
        "walk_in" => 0, "click_collect" => 1, "local_delivery" => 2, "phone_hold" => 3
      )
    end
    it do
      expect(Order.fulfillment_statuses).to eq(
        "unfulfilled" => 0, "ready" => 1, "handed_over" => 2
      )
    end
  end

  describe "order codes" do
    it "assigns a unique code when the order is created without one" do
      company = create(:company)
      customer = create(:customer, company: company)
      first = create(:order, company: company, customer: customer)
      second = create(:order, company: company, customer: customer)

      expect(first.code).to match(/\AORD-[0-9A-F]{8}\z/)
      expect(second.code).to match(/\AORD-[0-9A-F]{8}\z/)
      expect(first.code).not_to eq(second.code)
    end

    it "keeps a code supplied by the caller" do
      company = create(:company)
      order = create(:order, company: company, customer: create(:customer, company: company), code: "ORD-CUSTOM1")

      expect(order.code).to eq("ORD-CUSTOM1")
    end
  end
  it_behaves_like "property_mapping concern", Order
end
