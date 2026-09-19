require "rails_helper"

RSpec.feature "Companies::Purchases Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:purchase_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }

  let!(:workflow) do
    Seed::WorkflowService.create(
      company: company, category: purchase_category,
      name: "Office Supplies Purchase Process", process_type: :purchase_process
    ).tap do |workflow|
      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 }
      ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
    end
  end

  let!(:purchase_item) { create(:purchase_item, company: company, name: "Ballpoint Pen") }
  let!(:purchase) { create(:purchase, company: company, category: purchase_category, name: "Pens restock") }
  let!(:appointment) do
    Seed::PurchaseItemAppointmentService.create(
      company: company, purchase: purchase, purchase_item: purchase_item,
      quantity: 5, unit_price: 2.50
    )
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "shows purchase details, items table and workflow steps" do
    visit company_purchase_path(company, purchase)

    expect(page).to have_content('Pens restock', wait: 10)
    expect(page).to have_content('Ballpoint Pen', wait: 10)
    expect(page).to have_content('Submit', wait: 10)
    expect(page).to have_content('Manager Approval', wait: 10)
    expect(page).to have_button('Approve', wait: 10)
    expect(page).to have_button('Reject', wait: 10)
  end

  scenario "approve advances the workflow to the next step" do
    visit company_purchase_path(company, purchase)
    expect(page).to have_button('Approve', wait: 10)

    click_button "Approve"

    expect(page).to have_content('Manager Approval', wait: 10)

    expect(purchase.reload.workflow_step).to eq(workflow.workflow_steps.find_by(position: 2))
    expect(purchase.reload.workflow_status_confirmed?).to be true
  end

  scenario "reject cancels the workflow" do
    visit company_purchase_path(company, purchase)
    expect(page).to have_button('Reject', wait: 10)

    click_button "Reject"

    expect(page).to have_no_button('Approve', wait: 10)

    expect(purchase.reload.workflow_status_cancelled?).to be true
    expect(purchase.reload.workflow_step).to eq(workflow.workflow_steps.find_by(position: 1))
  end
end
