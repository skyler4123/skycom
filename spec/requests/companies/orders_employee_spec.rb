# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders employee attribution", type: :request do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:employee) { create(:employee, company: company, name: "Sales Employee") }
  let(:customer) { create(:customer, company: company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "orders") }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: owner.email)
  end

  def order_params(employee_id:)
    {
      order: {
        name: "Sold order #{SecureRandom.hex(3)}",
        customer_id: customer.id,
        category_id: category.id,
        business_type: "in_store",
        currency: "usd",
        workflow_status: "pending",
        employee_id: employee_id
      }
    }
  end

  it "lists employees for the picker" do
    get "/companies/#{company.id}/orders/new.json"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["employees"].map { |row| row["id"] }).to include(employee.id)
  end

  it "persists the employee on create" do
    expect do
      post "/companies/#{company.id}/orders", params: order_params(employee_id: employee.id)
    end.to change(Order, :count).by(1)

    expect(Order.last.employee).to eq(employee)
  end

  it "refuses an employee from another company" do
    other_employee = create(:employee)

    expect do
      post "/companies/#{company.id}/orders", params: order_params(employee_id: other_employee.id)
    end.not_to change(Order, :count)
  end

  it "includes the employee in the show payload" do
    order = create(:order, company: company, customer: customer, employee: employee)

    get "/companies/#{company.id}/orders/#{order.id}.json"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["order"]["employee"]).to include("id" => employee.id)
  end
end
