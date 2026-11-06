require "rails_helper"

RSpec.feature "Companies::Categories New Category link", type: :feature, js: true do
  NEW_CATEGORY_PAGES = [
    { label: "branches", path_helper: :new_company_branch_path, resource_name: "branches" },
    { label: "brands", path_helper: :new_company_brand_path, resource_name: "brands" },
    { label: "customer profiles", path_helper: :new_company_customer_profile_path, resource_name: "customer_profiles" },
    { label: "customer subprofiles", path_helper: :new_company_customer_subprofile_path, resource_name: "customer_subprofiles" },
    { label: "customers", path_helper: :new_company_customer_path, resource_name: "customers" },
    { label: "departments", path_helper: :new_company_department_path, resource_name: "departments" },
    { label: "documents", path_helper: :new_company_document_path, resource_name: "documents" },
    { label: "employee groups", path_helper: :new_company_employee_group_path, resource_name: "employee_groups" },
    { label: "employee profiles", path_helper: :new_company_employee_profile_path, resource_name: "employee_profiles" },
    { label: "employee subprofiles", path_helper: :new_company_employee_subprofile_path, resource_name: "employee_subprofiles" },
    { label: "employees", path_helper: :new_company_employee_path, resource_name: "employees" },
    { label: "events", path_helper: :new_company_event_path, resource_name: "events" },
    { label: "facilities", path_helper: :new_company_facility_path, resource_name: "facilities" },
    { label: "invoices", path_helper: :new_company_invoice_path, resource_name: "invoices" },
    { label: "orders", path_helper: :new_company_order_path, resource_name: "orders" },
    { label: "products", path_helper: :new_company_product_path, resource_name: "products" },
    { label: "purchases", path_helper: :new_company_purchase_path, resource_name: "purchases" },
    { label: "questions", path_helper: :new_company_question_path, resource_name: "questions" },
    { label: "services", path_helper: :new_company_service_path, resource_name: "services" },
    { label: "stock adjustments", path_helper: :new_company_stock_adjustment_path, resource_name: "stock_adjustments" },
    { label: "stock exports", path_helper: :new_company_stock_export_path, resource_name: "stock_exports" },
    { label: "stock imports", path_helper: :new_company_stock_import_path, resource_name: "stock_imports" },
    { label: "stock transfers", path_helper: :new_company_stock_transfer_path, resource_name: "stock_transfers" },
    { label: "suppliers", path_helper: :new_company_supplier_path, resource_name: "suppliers" },
    { label: "tickets", path_helper: :new_company_ticket_path, resource_name: "tickets" },
    { label: "warehouses", path_helper: :new_company_warehouse_path, resource_name: "warehouses" },
    { label: "workflows", path_helper: :new_company_workflow_path, resource_name: "purchases" }
  ].freeze

  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:owner_employee) { company.employees.find_by(user: owner) }

  before do
    sign_in(owner)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => [],
      "workflows" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: owner_employee ? [ JSON.parse(owner_employee.to_json) ] : []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  NEW_CATEGORY_PAGES.each do |page_entry|
    scenario "shows the New Category link on the #{page_entry[:label]} new page" do
      visit public_send(page_entry[:path_helper], company)

      expected_href = new_company_category_path(company, resource_name: page_entry[:resource_name])
      expect(page).to have_selector("a[href='#{expected_href}']", text: "New Category", wait: 10)
    end
  end

  scenario "clicking New Category opens the category form with the resource preselected" do
    visit new_company_product_path(company)

    expected_href = new_company_category_path(company, resource_name: "products")
    find("a[href='#{expected_href}']", wait: 10).click

    expect(page).to have_current_path(new_company_category_path(company), ignore_query: true, wait: 10)
    expect(find("select[name='category[resource_name]']").value).to eq("products")
  end
end
