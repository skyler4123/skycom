# app/services/client_cache/enums_builder.rb

# Single source of truth for the enum payload served by GET /client_cache and
# seeded in feature specs (spec/support/client_cache_seeding.rb). Never
# hardcode enum option arrays in Stimulus controllers — the cache is always
# present when a form renders (page rendering is gated on currentCompany(),
# which reads the same localStorage blob as Enums()).
class ClientCache::EnumsBuilder
  def self.build
    {
      employee: {
        lifecycle_statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Employee.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      branch: {
        lifecycle_statuses: Branch.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Branch.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Branch.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      department: {
        lifecycle_statuses: LIFECYCLE_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
        workflow_statuses: WORKFLOW_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
        business_types: Department.business_types.keys.map { |t| { name: t.to_s.humanize, value: t.to_s } }
      },
      brand: {
        lifecycle_statuses: Brand.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Brand.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Brand.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      facility: {
        lifecycle_statuses: Facility.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Facility.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Facility.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      category: {
        lifecycle_statuses: LIFECYCLE_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
        workflow_statuses: WORKFLOW_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
        resource_names: [ "products", "employees", "branches", "departments", "brands", "customers", "services", "facilities" ]
      },
      product: {
        lifecycle_statuses: Product.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Product.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Product.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      service: {
        lifecycle_statuses: Service.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Service.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Service.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      order: {
        lifecycle_statuses: Order.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Order.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Order.business_types.keys.map { |t| { name: t.humanize, value: t } },
        currencies: Order.currencies.keys.map { |c| { name: c.humanize, value: c } }
      },
      customer: {
        lifecycle_statuses: Customer.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Customer.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Customer.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      invoice: {
        lifecycle_statuses: Invoice.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Invoice.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Invoice.business_types.keys.map { |t| { name: t.humanize, value: t } },
        currencies: Invoice.currencies.keys.map { |c| { name: c.humanize, value: c } }
      },
      company: {
        business_types: Company.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      stock: {
        lifecycle_statuses: Stock.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: Stock.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: Stock.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      stock_transfer: {
        lifecycle_statuses: StockTransfer.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: StockTransfer.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: StockTransfer.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      stock_import: {
        lifecycle_statuses: StockImport.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: StockImport.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: StockImport.business_types.keys.map { |t| { name: t.humanize, value: t } }
      },
      stock_export: {
        lifecycle_statuses: StockExport.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        workflow_statuses: StockExport.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
        business_types: StockExport.business_types.keys.map { |t| { name: t.humanize, value: t } }
      }
    }
  end
end
