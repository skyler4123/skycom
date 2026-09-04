require "rails_helper"

RSpec.describe "DynamicSearchConcern" do
  before(:all) do
    @meili_available = begin
      Meilisearch::Rails.client.health["status"] == "available"
    rescue StandardError
      false
    end
    unless @meili_available
      raise "Meilisearch not reachable at #{Meilisearch::Rails.configuration[:meilisearch_url]}. Run `docker compose up -d meilisearch`."
    end
  end

  describe "connection to Meilisearch" do
    it "returns a healthy status" do
      expect(Meilisearch::Rails.client.health).to eq("status" => "available")
    end
  end

  describe "index settings" do
    it "applies searchable + filterable attributes for a dynamic model" do
      settings = Product.ms_index.settings
      expect(settings["searchableAttributes"]).to include("name", "description", "code", "property_string_1", "property_integer_1")
      expect(settings["filterableAttributes"]).to include("company_id", "property_integer_1", "property_boolean_1")
    end
  end
end

require_relative "../../support/shared_examples/dynamic_search"

DYNAMIC_SEARCH_MODELS = {
  Answer => ->(company) {
    question = create_searchable_record(Question, company, "questions")
    create_searchable_record(Answer, company, "answers", question: question)
  },
  Article => ->(company) {
    article_group = create_searchable_record(ArticleGroup, company, "article_groups")
    create_searchable_record(Article, company, "articles", article_group: article_group)
  },
  ArticleGroup => ->(company) { create_searchable_record(ArticleGroup, company, "article_groups") },
  Branch => ->(company) { create(:branch, company: company) },
  Brand => ->(company) { create(:brand, company: company) },
  Cart => ->(company) {
    cart_group = create_searchable_record(CartGroup, company, "cart_groups")
    create_searchable_record(Cart, company, "carts", cart_group: cart_group)
  },
  CartGroup => ->(company) { create_searchable_record(CartGroup, company, "cart_groups") },
  Customer => ->(company) { create(:customer, company: company) },
  CustomerGroup => ->(company) { create_searchable_record(CustomerGroup, company, "customer_groups") },
  Department => ->(company) { create(:department, company: company) },
  Document => ->(company) {
    document_group = create_searchable_record(DocumentGroup, company, "document_groups")
    create_searchable_record(Document, company, "documents", document_group: document_group)
  },
  DocumentGroup => ->(company) { create_searchable_record(DocumentGroup, company, "document_groups") },
  Employee => ->(company) { create(:employee, company: company, user: create(:user), branch: create(:branch, company: company)) },
  EmployeeGroup => ->(company) { create(:employee_group, company: company) },
  Event => ->(company) {
    event_group = create_searchable_record(EventGroup, company, "event_groups")
    create_searchable_record(Event, company, "events", event_group: event_group)
  },
  EventGroup => ->(company) { create_searchable_record(EventGroup, company, "event_groups") },
  Exam => ->(company) {
    exam_group = create_searchable_record(ExamGroup, company, "exam_groups")
    create_searchable_record(Exam, company, "exams", exam_group: exam_group)
  },
  ExamGroup => ->(company) { create_searchable_record(ExamGroup, company, "exam_groups") },
  Facility => ->(company) { create(:facility, company: company) },
  FacilityGroup => ->(company) { create_searchable_record(FacilityGroup, company, "facility_groups") },
  Invoice => ->(company) {
    customer = create(:customer, company: company)
    order = create(:order, company: company, customer: customer)
    create(:invoice, order: order)
  },
  Membership => ->(company) { create_searchable_record(Membership, company, "memberships", code: "MEM-#{SecureRandom.hex(4)}", name: "UniqueSearchTerm#{SecureRandom.hex(4)}") },
  Notification => ->(company) {
    notification_group = create_searchable_record(NotificationGroup, company, "notification_groups")
    create_searchable_record(Notification, company, "notifications", notification_group: notification_group)
  },
  NotificationGroup => ->(company) { create_searchable_record(NotificationGroup, company, "notification_groups") },
  Order => ->(company) {
    customer = create(:customer, company: company)
    create(:order, company: company, customer: customer)
  },
  OrderGroup => ->(company) {
    customer = create(:customer, company: company)
    create_searchable_record(OrderGroup, company, "order_groups", customer: customer)
  },
  Product => ->(company) { create(:product, company: company) },
  ProductGroup => ->(company) { create_searchable_record(ProductGroup, company, "product_groups") },
  Project => ->(company) {
    project_group = create_searchable_record(ProjectGroup, company, "project_groups")
    create_searchable_record(Project, company, "projects", project_group: project_group)
  },
  ProjectGroup => ->(company) { create_searchable_record(ProjectGroup, company, "project_groups") },
  Purchase => ->(company) { create_searchable_record(Purchase, company, "purchases") },
  PurchaseItem => ->(company) {
    purchase = create_searchable_record(Purchase, company, "purchases")
    create_searchable_record(PurchaseItem, company, "purchase_items", purchase: purchase)
  },
  Question => ->(company) { create_searchable_record(Question, company, "questions") },
  Reservation => ->(company) { create_searchable_record(Reservation, company, "reservations", code: "RES-#{SecureRandom.hex(4)}") },
  Service => ->(company) { create_searchable_record(Service, company, "services") },
  ServiceGroup => ->(company) { create_searchable_record(ServiceGroup, company, "service_groups") },
  SettingGroup => ->(company) { create_searchable_record(SettingGroup, company, "setting_groups") },
  Stock => ->(company) { create(:stock, warehouse: create(:warehouse, company: company), product: create(:product, company: company)) },
  StockExport => ->(company) { create_seed_record(Seed::StockExportService, company, "stock_exports", product: create(:product, company: company), warehouse: create(:warehouse, company: company)) },
  StockImport => ->(company) { create_seed_record(Seed::StockImportService, company, "stock_imports", product: create(:product, company: company), warehouse: create(:warehouse, company: company)) },
  StockTransfer => ->(company) { create_seed_record(Seed::StockTransferService, company, "stock_transfers", product: create(:product, company: company), warehouse: create(:warehouse, company: company)) },
  TableConfig => ->(company) {
    category = create(:category, company: company, resource_name: "products")
    # The factory's TableConfig columns expect property_string_1 to be named
    # "Skin Type", but the category factory assigns random labels — force the
    # mapping to match so the column name validation never flakes.
    pm = category.default_property_mapping
    props = (pm.properties || []).reject { |p| p["key"] == "property_string_1" }
    props << { "key" => "property_string_1", "type" => "string", "name" => "Skin Type", "validates" => {} }
    pm.update!(metadata: { "properties" => props })
    create(:table_config, company: company, category: category, property_mapping: pm)
  },
  Task => ->(company) {
    task_group = create_searchable_record(TaskGroup, company, "task_groups")
    create_searchable_record(Task, company, "tasks", task_group: task_group)
  },
  TaskGroup => ->(company) { create_searchable_record(TaskGroup, company, "task_groups") },
  Transaction => ->(company) {
    customer = create(:customer, company: company)
    order = create(:order, company: company, customer: customer)
    invoice = create(:invoice, order: order)
    create_searchable_record(Transaction, company, "transactions", invoice: invoice, branch: create(:branch, company: company))
  },
  Warehouse => ->(company) { create(:warehouse, company: company) }
}.freeze

RSpec.describe "dynamic meilisearch models" do
  def create_searchable_record(model_class, company, resource_name, **extra)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: resource_name)
    attrs = { company: company, category: category, property_mapping: category.default_property_mapping }

    if model_class.column_names.include?("name") && !extra.key?(:name)
      attrs[:name] = "#{model_class.name} #{SecureRandom.hex(4)}"
    end
    if model_class.column_names.include?("code") && !extra.key?(:code)
      attrs[:code] = "#{model_class.name[0, 3].upcase}-#{SecureRandom.hex(4).upcase}"
    end
    %i[business_type workflow_status lifecycle_status].each do |enum_name|
      plural = enum_name.to_s.pluralize
      if model_class.respond_to?(plural) && model_class.column_names.include?(enum_name.to_s) && !extra.key?(enum_name)
        attrs[enum_name] = model_class.public_send(plural).keys.sample
      end
    end

    model_class.create!(attrs.merge(extra))
  end

  def create_seed_record(service_class, company, resource_name, **kwargs)
    service_class.new(company: company, **kwargs).tap do |record|
      if record.category.nil? && record.company.present?
        record.category = Seed::CategoryService.find_or_create_for(company: record.company, resource_name: resource_name)
      end
      if record.property_mapping.nil? && record.category.present?
        record.property_mapping = record.category.default_property_mapping
      end
      record.save!
    end
  end

  DYNAMIC_SEARCH_MODELS.each do |model_class, builder|
    it_behaves_like "dynamic meilisearch model", model_class, builder
  end
end
