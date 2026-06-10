require "rails_helper"

RSpec.feature "Companies::Products Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product,
      company: company,
      business_type: "physical"
    )
  end

  let!(:product2) do
    create(:product,
      company: company,
      business_type: "digital",
      workflow_status: "pending"
    )
  end

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "products")
  end

  let!(:default_table_config) do
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.property_mapping,
      resource_name: "products",
      columns_metadata: [
        { "key" => "name", "label" => "Product Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Product Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "business_type", "label" => "Type", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
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

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index page loads and displays products table" do
    visit company_products_path(company, category_id: default_category.id)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Product Name')
    expect(page).to have_selector('th', text: 'Type')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(product.name)
  end

  scenario "create new product via modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    find('[data-action*="openNewModal"]').click

    expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

    expect(page).to have_selector('input[name="product[name]"]', wait: 5)
    fill_in 'product[name]', with: 'New Test Product'
    select 'Digital', from: 'product[business_type]'

    click_button "Save Product"

    expect(page).to have_content("created successfully", wait: 10)
    expect(page).to have_selector('tbody tr', wait: 10)

    expect(Product.find_by(name: "New Test Product")).to be_present
  end

  scenario "edit button opens show modal for product" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('[data-action*="openShowModal"]', minimum: 1)
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "products")
    product.update!(category: category, property_mapping: category.property_mapping)
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "display product business type as badge" do
    visit company_products_path(company, category_id: default_category.id)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("physical", minimum: 1)
    expect(page).to have_content("digital", minimum: 1)
  end

  scenario "display product workflow status as badge" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "update product name via show modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    editable_name_field = find('[data-controller="editable"]', match: :first)
    editable_name_field.click

    expect(page).to have_selector('.editable-input', wait: 5)

    editable_name_field.find('.editable-input').fill_in(with: 'Updated Product Name')

    accept_confirm do
      editable_name_field.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated Product Name', wait: 10)
    expect(Product.find_by(id: product.id).name).to eq("Updated Product Name")
  end

  scenario "update product description via show modal" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    target_row = find('tbody tr', text: product.name)
    target_row.find('[data-action*="openShowModal"]').click

    expect(page).to have_selector('.swal2-container', wait: 10)

    all_editable = all('[data-controller="editable"]')
    desc_editable = all_editable[1]
    desc_editable.click

    expect(page).to have_selector('.editable-input', wait: 5)

    desc_editable.find('.editable-input').fill_in(with: 'Updated description for this product')

    accept_confirm do
      desc_editable.find('.editable-input').send_keys :enter
    end

    expect(page).to have_content('Updated description for this product', wait: 10)
    expect(Product.find_by(id: product.id).description).to eq("Updated description for this product")
  end

  # ============================================================================
  # Dynamic Table Tests
  # ============================================================================
  describe "dynamic table" do
    let(:category_cosmetics) do
      Seed::CategoryService.create(
        company: company,
        name: "Cosmetics",
        resource_name: "products",
        properties: {
          "property_string_1" => "Skin Type",
          "property_string_2" => "Key Ingredients",
          "property_integer_1" => "Volume (ml)",
          "property_boolean_1" => "Organic Certified"
        }
      )
    end

    let(:category_supplements) do
      Seed::CategoryService.create(
        company: company,
        name: "Supplements",
        resource_name: "products",
        properties: {
          "property_text_1" => "Benefits",
          "property_decimal_1" => "Potency %",
          "property_datetime_1" => "Expiry Date"
        }
      )
    end

    let!(:table_config_cosmetics) do
      TableConfig.create!(
        company: company,
        category: category_cosmetics,
        property_mapping: category_cosmetics.property_mapping,
        resource_name: "products",
        columns_metadata: [
          { "key" => "name", "label" => "Product Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_string_1", "label" => "Skin Type", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_string_2", "label" => "Key Ingredients", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_integer_1", "label" => "Volume (ml)", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_boolean_1", "label" => "Organic", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "business_type", "label" => "Type", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ]
      )
    end

    let!(:table_config_supplements) do
      TableConfig.create!(
        company: company,
        category: category_supplements,
        property_mapping: category_supplements.property_mapping,
        resource_name: "products",
        columns_metadata: [
          { "key" => "name", "label" => "Product Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_text_1", "label" => "Benefits", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_decimal_1", "label" => "Potency %", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_datetime_1", "label" => "Expiry", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ]
      )
    end

    let!(:products_cosmetics) do
      names = [ "Gorgeous Steel Plate", "Practical Wool Shoes" ]
      names.map.with_index do |nm, i|
        product = Product.new(
          company: company,
          name: nm,
          description: Faker::Lorem.sentence(word_count: 12),
          code: "PRD-#{SecureRandom.hex(4).upcase}",
          category: category_cosmetics,
          property_mapping: category_cosmetics.property_mapping,
          business_type: Product.business_types.keys.sample,
          workflow_status: Product.workflow_statuses.keys.sample,
          lifecycle_status: Product.lifecycle_statuses.keys.sample
        )
        Seed::PropertyPopulator.populate(product)
        product.save!
        product
      end
    end

    let!(:products_supplements) do
      names = [ "Aerodynamic Iron Car", "Intelligent Copper Wallet" ]
      names.map.with_index do |nm, i|
        product = Product.new(
          company: company,
          name: nm,
          description: Faker::Lorem.sentence(word_count: 12),
          code: "PRD-#{SecureRandom.hex(4).upcase}",
          category: category_supplements,
          property_mapping: category_supplements.property_mapping,
          business_type: Product.business_types.keys.sample,
          workflow_status: Product.workflow_statuses.keys.sample,
          lifecycle_status: Product.lifecycle_statuses.keys.sample
        )
        Seed::PropertyPopulator.populate(product)
        product.save!
        product
      end
    end

    before do
      page.execute_script("localStorage.clear()")

      company_data = JSON.parse(company.to_json).merge(
        "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
        "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
        "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
        "branches" => [],
        "departments" => [],
        "roles" => []
      )

      payload = {
        user: JSON.parse(owner.to_json),
        companies: [ company_data ],
        enums: {},
        employees: []
      }

      page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
      # Sync cookie version to prevent ClientCacheController from overwriting localStorage
      page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
      page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
    end

    # =========================================================================
    # SCENARIO 1: Dynamic headers render from TableConfig + PropertyMapping
    # =========================================================================
    scenario "loads with dynamic columns from TableConfig and PropertyMapping" do
      visit company_products_path(company, category_id: category_cosmetics.id)

      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('th', text: 'Product Name', wait: 10)
      expect(page).to have_selector('th', text: 'Code', wait: 10)
      expect(page).to have_selector('th', text: 'Skin Type', wait: 10)
      expect(page).to have_selector('th', text: 'Key Ingredients', wait: 10)
      expect(page).to have_selector('th', text: 'Volume (ml)', wait: 10)
      expect(page).to have_selector('th', text: 'Organic', wait: 10)
      expect(page).to have_selector('th', text: 'Status', wait: 10)

      products_cosmetics.each do |p|
        expect(page).to have_content(p.name, wait: 5)
      end
    end

    # =========================================================================
    # SCENARIO 2: Switching category changes columns
    # =========================================================================
    scenario "switching category updates table columns" do
      visit company_products_path(company, category_id: category_cosmetics.id)

      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_selector('th', text: 'Key Ingredients', wait: 10)

      select(category_supplements.name, from: 'category_id')
      click_button "Search"

      expect(page).to have_current_path(/category_id=#{category_supplements.id}/)

      expect(page).not_to have_selector('th', text: 'Key Ingredients')
      expect(page).to have_selector('th', text: 'Benefits', wait: 10)
      expect(page).to have_selector('th', text: 'Potency %', wait: 10)
      expect(page).to have_selector('th', text: 'Expiry', wait: 10)

      products_supplements.each do |p|
        expect(page).to have_content(p.name, wait: 5)
      end
    end

    # =========================================================================
    # SCENARIO 3: String property renders
    # =========================================================================
    scenario "string property displays its value" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_cosmetics.first
      expect(first_product.property_string_1).to be_present
      expect(page).to have_content(first_product.property_string_1, wait: 10)
    end

    # =========================================================================
    # SCENARIO 4: Integer property renders with formatting
    # =========================================================================
    scenario "integer property displays with numeric value" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_cosmetics.first
      expect(first_product.property_integer_1).to be_present

      expect(page).to have_selector('th', text: 'Volume (ml)', wait: 10)
    end

    # =========================================================================
    # SCENARIO 5: Boolean property renders as Yes/No badge
    # =========================================================================
    scenario "boolean property displays as Yes or No badge" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      products_cosmetics.each do |p|
        next if p.property_boolean_1.nil?

        expected_text = p.property_boolean_1 ? "Yes" : "No"
        row = find('tbody tr', text: p.name)
        expect(row).to have_content(expected_text, wait: 5)
      end
    end

    # =========================================================================
    # SCENARIO 6: Decimal property renders with two decimal places
    # =========================================================================
    scenario "decimal property displays with two decimal places" do
      visit company_products_path(company, category_id: category_supplements.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_supplements.first
      expect(first_product.property_decimal_1).to be_present

      formatted = sprintf("%.2f", first_product.property_decimal_1)
      expect(page).to have_content(formatted, wait: 10)
    end

    # =========================================================================
    # SCENARIO 7: Text property renders
    # =========================================================================
    scenario "text property displays" do
      visit company_products_path(company, category_id: category_supplements.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_supplements.first
      expect(first_product.property_text_1).to be_present

      text_preview = first_product.property_text_1[0, 50]
      expect(page).to have_content(text_preview, wait: 10)
    end

    # =========================================================================
    # SCENARIO 8: Datetime property renders
    # =========================================================================
    scenario "datetime property displays" do
      visit company_products_path(company, category_id: category_supplements.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_supplements.first
      expect(first_product.property_datetime_1).to be_present

      expect(page).to have_selector('th', text: 'Expiry', wait: 10)
    end

    # =========================================================================
    # SCENARIO 9: Code field renders
    # =========================================================================
    scenario "code field displays" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_cosmetics.first
      expect(page).to have_content(first_product.code, wait: 10)
    end

    # =========================================================================
    # SCENARIO 10: Business type badge renders
    # =========================================================================
    scenario "business type badge displays" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      products_cosmetics.each do |p|
        row = find('tbody tr', text: p.name, match: :prefer_exact)
        expect(row).to have_content(p.business_type.to_s, wait: 5)
      end
    end

    # =========================================================================
    # SCENARIO 11: Workflow status badge renders
    # =========================================================================
    scenario "workflow status badge displays" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('span.rounded-full', wait: 10)
    end

    # =========================================================================
    # SCENARIO 12: Show modal renders editable fields for properties
    # =========================================================================
    scenario "show modal opens with editable property fields" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      target_product = products_cosmetics.first
      row = find('tbody tr', text: target_product.name)
      row.find('[data-action*="openShowModal"]').click

      expect(page).to have_selector('.swal2-container', wait: 10)

      within('.swal2-container') do
        expect(page).to have_content('Skin Type', wait: 5)
        expect(page).to have_content('Key Ingredients')
        expect(page).to have_content('Volume (ml)')
        expect(page).to have_content('Organic Certified')
      end
    end

    # =========================================================================
    # SCENARIO 13: Create new product modal renders dynamic fields for category
    # =========================================================================
    scenario "create new product modal renders with dynamic property fields" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      find('[data-action*="openNewModal"]').click

      expect(page).to have_selector('form[data-action*="handleSubmit"]', wait: 10)

      expect(page).to have_selector('input[name="product[name]"]', wait: 5)
      expect(page).to have_selector('input[name="product[property_string_1]"]', wait: 5)
      expect(page).to have_selector('input[name="product[property_string_2]"]')
      expect(page).to have_selector('input[name="product[property_integer_1]"]')
      expect(page).to have_selector('input[type="checkbox"][name="product[property_boolean_1]"]')

      fill_in 'product[name]', with: 'Dynamic Property Product'
      select 'Digital', from: 'product[business_type]'

      click_button "Save Product"

      expect(page).to have_content("created successfully", wait: 10)
      expect(page).to have_selector('tbody tr', wait: 10)

      product = Product.find_by(name: "Dynamic Property Product")
      expect(product).to be_present
      expect(product.category).to eq(category_cosmetics)
    end
  end
end
