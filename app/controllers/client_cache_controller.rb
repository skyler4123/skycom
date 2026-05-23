# app/controllers/client_cache_controller.rb

# Give the latest cache for client
class ClientCacheController < ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          user: current_user.as_json,
          companies: current_user.accessible_companies.as_json(include: [ :branches, :departments, :roles, :company_configs, :categories, :property_mappings, :table_configs ]),
          enums: {
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
              currency_codes: Order.currency_codes.keys.map { |c| { name: c.humanize, value: c } }
            },
            booking: {
              lifecycle_statuses: LIFECYCLE_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
              workflow_statuses: WORKFLOW_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } }
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
              currency_codes: Invoice.currency_codes.keys.map { |c| { name: c.humanize, value: c } }
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
          },
          employees: current_user.employees
        }
      end
    end
  end
end
