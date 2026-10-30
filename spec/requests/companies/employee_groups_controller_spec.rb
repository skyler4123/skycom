# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::EmployeeGroupsController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "employee_groups" }
    let(:index_class) { EmployeeGroup }
    let(:json_key) { "employee_groups" }
    let(:base_json_path) { "/companies/#{company.id}/employee_groups.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        name = attrs.delete(:name)
        employee_group = Seed::EmployeeGroupService.create(
          company: company,
          category: category,
          name: name
        )
        employee_group.update!(attrs) if attrs.any?
        employee_group
      end
    end
  end
end

RSpec.describe "Companies::EmployeeGroupsController tenant scoping", type: :request do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:category) { create_employee_group_category!(company: company) }
  let(:manager) { create_employee!(company: company, branch: branch, name: "Scoped Manager") }

  let(:other_company) { create(:company) }
  let(:other_branch) { create(:branch, company: other_company) }
  let(:other_category) { create_employee_group_category!(company: other_company) }
  let(:other_employee) { create_employee!(company: other_company, branch: other_branch, name: "Other Employee") }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  scenario "show does not expose another company's group" do
    other_group = create_employee_group!(
      company: other_company,
      category: other_category,
      name: "Other Company Team"
    )

    get "/companies/#{company.id}/employee_groups/#{other_group.id}.json"

    expect(response).to have_http_status(:not_found)
    expect(JSON.parse(response.body)["errors"]).to include("Employee group not found")
  end

  scenario "create ignores employee ids from another company" do
    post "/companies/#{company.id}/employee_groups", params: {
      employee_group: {
        name: "Scoped Team",
        category_id: category.id,
        manager_id: manager.id,
        employee_ids: [ manager.id, other_employee.id ]
      }
    }

    expect(response).to redirect_to(%r{/employee_groups/})

    employee_group = EmployeeGroup.find_by!(company: company, name: "Scoped Team")
    expect(employee_group.employees).to include(manager)
    expect(employee_group.employees).not_to include(other_employee)
  end

  scenario "edit JSON includes the company employee reference list" do
    employee_group = create_employee_group!(
      company: company,
      category: category,
      name: "Edit Team",
      manager: manager
    )

    get "/companies/#{company.id}/employee_groups/#{employee_group.id}/edit.json"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload["employee_group"]["id"]).to eq(employee_group.id)
    expect(payload["employees"].map { |employee| employee["id"] }).to include(manager.id)
  end

  scenario "create ignores malformed employee ids" do
    post "/companies/#{company.id}/employee_groups", params: {
      employee_group: {
        name: "Safe Team",
        category_id: category.id,
        manager_id: manager.id,
        employee_ids: [ "not-a-uuid" ]
      }
    }

    expect(response).to redirect_to(%r{/employee_groups/})

    employee_group = EmployeeGroup.find_by!(company: company, name: "Safe Team")
    expect(employee_group.employees).to include(manager)
  end

  scenario "create ignores category and branch ids from another company" do
    post "/companies/#{company.id}/employee_groups", params: {
      employee_group: {
        name: "Tenant Safe Team",
        category_id: other_category.id,
        branch_id: other_branch.id,
        manager_id: manager.id
      }
    }

    employee_group = EmployeeGroup.find_by!(company: company, name: "Tenant Safe Team")
    expect(employee_group.category.company_id).to eq(company.id)
    expect(employee_group.branch_id).to be_nil
  end

  scenario "create rejects a manager from another company" do
    post "/companies/#{company.id}/employee_groups", params: {
      employee_group: {
        name: "Bad Team",
        category_id: category.id,
        manager_id: other_employee.id
      }
    }

    expect(response).to redirect_to(new_company_employee_group_path(company))
    expect(flash[:alert]).to include("Manager must belong to the same company")
    expect(EmployeeGroup.where(company: company, name: "Bad Team")).not_to exist
  end
end
