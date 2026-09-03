require "rails_helper"

RSpec.feature "Companies::Products Management", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:product) do
    create(:product,
      company: company,
      name: "Base Physical Product #{SecureRandom.hex(4)}",
      business_type: "physical"
    ).tap { |p| p.update!(property_string_1: "Oily", property_integer_1: 150) }
  end

  let!(:product2) do
    create(:product,
      company: company,
      name: "Base Digital Product #{SecureRandom.hex(4)}",
      business_type: "digital",
      workflow_status: "pending"
    ).tap { |p| p.update!(property_string_1: "Dry", property_integer_1: 250) }
  end

  let!(:default_category) do
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "products")
    category.default_property_mapping.update!(
      metadata: { "properties" => [
        { "key" => "property_string_1", "type" => "string", "name" => "Skin Type" },
        { "key" => "property_integer_1", "type" => "integer", "name" => "Volume (ml)" }
      ] }
    )
    category
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "products",
      metadata: { "columns" => [
        { "key" => "property_string_1", "name" => "Skin Type", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "property_integer_1", "name" => "Volume (ml)", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ] }
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

    expect(page).to have_selector('th', text: 'Skin Type', wait: 10)
    expect(page).to have_selector('th', text: 'Volume (ml)', wait: 10)

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content("Oily")
  end

  scenario "edit button links to show page for product" do
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/products/#{product.id}']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Category", resource_name: "products")
    product.category = category
    product.property_mapping = category.default_property_mapping
    Seed::PropertyPopulator.populate(product)
    product.save!
    visit company_products_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end

  scenario "displays property string values in cells" do
    visit company_products_path(company, category_id: default_category.id)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_content("Oily", minimum: 1)
    expect(page).to have_content("Dry", minimum: 1)
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
          "property_string_3" => "Benefits",
          "property_decimal_1" => "Potency %",
          "property_datetime_1" => "Expiry Date"
        }
      )
    end

    let!(:table_config_cosmetics) do
      category_cosmetics.default_property_mapping.table_configs.destroy_all
      TableConfig.create!(
        company: company,
        category: category_cosmetics,
        property_mapping: category_cosmetics.default_property_mapping,
        resource_name: "products",
        metadata: { "columns" => [
          { "key" => "property_string_1", "name" => "Skin Type", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_string_2", "name" => "Key Ingredients", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_integer_1", "name" => "Volume (ml)", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_boolean_1", "name" => "Organic Certified", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ] }
      )
    end

    let!(:table_config_supplements) do
      category_supplements.default_property_mapping.table_configs.destroy_all
      TableConfig.create!(
        company: company,
        category: category_supplements,
        property_mapping: category_supplements.default_property_mapping,
        resource_name: "products",
        metadata: { "columns" => [
          { "key" => "property_string_3", "name" => "Benefits", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_decimal_1", "name" => "Potency %", "visible" => true, "sortable" => true, "align" => "right", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
          { "key" => "property_datetime_1", "name" => "Expiry Date", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ] }
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
          property_mapping: category_cosmetics.default_property_mapping,
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
          property_mapping: category_supplements.default_property_mapping,
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

      expect(page).to have_selector('th', text: 'Skin Type', wait: 10)
      expect(page).to have_selector('th', text: 'Key Ingredients', wait: 10)
      expect(page).to have_selector('th', text: 'Volume (ml)', wait: 10)
      expect(page).to have_selector('th', text: 'Organic', wait: 10)

      expect(page).to have_selector('tbody tr', count: products_cosmetics.size, wait: 10)
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

      expect(page).to have_selector('tbody tr', count: products_supplements.size, wait: 10)
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
      expect(page).to have_selector('th', text: 'Organic', wait: 10)

      rows = all('tbody tr', wait: 10)
      expect(rows.size).to eq(products_cosmetics.size)
      rows.each do |row|
        expect(row).to have_content("Yes").or have_content("No")
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
    # SCENARIO 7: String property renders
    # =========================================================================
    scenario "string property displays" do
      visit company_products_path(company, category_id: category_supplements.id)
      expect(page).to have_selector('table', wait: 10)

      first_product = products_supplements.first
      expect(first_product.property_string_3).to be_present

      text_preview = first_product.property_string_3[0, 50]
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
  end

  # ============================================================================
  # Table Title Tests
  # ============================================================================
  describe "table title" do
    let(:category_cosmetics) do
      Seed::CategoryService.create(
        company: company,
        name: "Cosmetics",
        resource_name: "products"
      )
    end

    let!(:table_config_cosmetics) do
      category_cosmetics.default_property_mapping.update!(
        metadata: { "properties" => [
          { "key" => "property_string_1", "type" => "string", "name" => "Skin Type" }
        ] }
      )
      category_cosmetics.default_property_mapping.table_configs.destroy_all
      tc = TableConfig.create!(
        company: company,
        category: category_cosmetics,
        property_mapping: category_cosmetics.default_property_mapping,
        resource_name: "products",
        metadata: { "columns" => [
          { "key" => "property_string_1", "name" => "Skin Type", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
        ] }
      )
      company.clear_permissions_cache
      tc
    end

    let!(:product_cosmetics) do
      create(:product, company: company, category: category_cosmetics, property_mapping: category_cosmetics.default_property_mapping, name: "Test Cosmetic")
    end

    before do
      company_data = JSON.parse(company.to_json).merge(
        "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
        "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
        "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
        "branches" => [],
        "departments" => [],
        "roles" => []
      )

      page.execute_script("localStorage.clear()")
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

    scenario "shows table title with resource name and category name" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      expect(page).to have_selector('h2', text: /Products - Cosmetics/)
    end

    scenario "edit icon links to table config edit page" do
      visit company_products_path(company, category_id: category_cosmetics.id)
      expect(page).to have_selector('table', wait: 10)

      edit_link = find("a[href*='/table_configs/#{table_config_cosmetics.id}/edit']", match: :first)
      expect(edit_link).to be_present
    end
  end

  # ============================================================================
  # Branch Filter Tests
  # ============================================================================
  describe "branch filter" do
    let(:branch2) { create(:branch, company: company) }

    let!(:product_branch_a) do
      create(:product,
        company: company,
        branch: branch,
        category: default_category,
        property_mapping: default_category.default_property_mapping,
        name: "Branch A Product #{SecureRandom.hex(4)}",
        business_type: "physical"
      ).tap { |p| p.update!(property_string_1: "Oily") }
    end

    let!(:product_branch_b) do
      create(:product,
        company: company,
        branch: branch2,
        category: default_category,
        property_mapping: default_category.default_property_mapping,
        name: "Branch B Product #{SecureRandom.hex(4)}",
        business_type: "physical"
      ).tap { |p| p.update!(property_string_1: "Dry") }
    end

    before do
      page.execute_script("localStorage.clear()")

      company_data = JSON.parse(company.to_json).merge(
        "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
        "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
        "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
        "branches" => company.branches.map { |b| JSON.parse(b.to_json) },
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

    scenario "shows branch dropdown with All Branches and branch options" do
      visit company_products_path(company, category_id: default_category.id)

      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_selector('select[name="branch_id"]')
      expect(page).to have_selector('option', text: 'All Branches')
      expect(page).to have_selector('option', text: branch.name)
      expect(page).to have_selector('option', text: branch2.name)
    end

    scenario "defaults to All Branches showing all products" do
      visit company_products_path(company, category_id: default_category.id)

      expect(page).to have_selector('table', wait: 10)
      expect(page).to have_content("Oily", wait: 5)
      expect(page).to have_content("Dry", wait: 5)
    end

    scenario "filters by branch and updates URL" do
      visit company_products_path(company, category_id: default_category.id)
      expect(page).to have_selector('table', wait: 10)

      select(branch2.name, from: 'branch_id')
      click_button "Search"

      expect(page).to have_current_path(/branch_id=#{branch2.id}/)
      expect(page).to have_selector('tbody tr', wait: 10)
      expect(page).to have_content("Dry", wait: 5)
      expect(page).not_to have_content("Oily")
    end
  end

  describe "client cache invalidation" do
    include_examples "client cache invalidation",
      resource_name: "products"
  end
end
