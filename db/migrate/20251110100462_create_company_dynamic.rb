class CreateCompanyDynamic < ActiveRecord::Migration[8.0]
  def change
    create_table :company_dynamics, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- BRANCH CACHE ---
      t.integer :branches_cache_version, default: 0

      # --- DEPARTMENT CACHE ---
      t.integer :departments_cache_version, default: 0

      # --- EMPLOYEE GROUP CACHE ---
      t.integer :employee_groups_cache_version, default: 0

      # --- EMPLOYEE CACHE ---
      t.integer :employees_cache_version, default: 0

      # --- CUSTOMER GROUP CACHE ---
      t.integer :customer_groups_cache_version, default: 0

      # --- CUSTOMER CACHE ---
      t.integer :customers_cache_version, default: 0

      # --- BRAND CACHE ---
      t.integer :brands_cache_version, default: 0

      # --- PRODUCT GROUP CACHE ---
      t.integer :product_groups_cache_version, default: 0

      # --- PRODUCT CACHE ---
      t.integer :products_cache_version, default: 0

      # --- WAREHOUSE CACHE ---
      t.integer :warehouses_cache_version, default: 0

      # --- STOCK CACHE ---
      t.integer :stocks_cache_version, default: 0

      # --- STOCK TRANSFER CACHE ---
      t.integer :stock_transfers_cache_version, default: 0

      # --- STOCK IMPORT CACHE ---
      t.integer :stock_imports_cache_version, default: 0

      # --- STOCK EXPORT CACHE ---
      t.integer :stock_exports_cache_version, default: 0

      # --- SERVICE GROUP CACHE ---
      t.integer :service_groups_cache_version, default: 0

      # --- SERVICE CACHE ---
      t.integer :services_cache_version, default: 0

      # --- ORDER GROUP CACHE ---
      t.integer :order_groups_cache_version, default: 0

      # --- ORDER CACHE ---
      t.integer :orders_cache_version, default: 0

      # --- CART GROUP CACHE ---
      t.integer :cart_groups_cache_version, default: 0

      # --- CART CACHE ---
      t.integer :carts_cache_version, default: 0

      # --- PURCHASE CACHE ---
      t.integer :purchases_cache_version, default: 0

      # --- PURCHASE ITEM CACHE ---
      t.integer :purchase_items_cache_version, default: 0

      # --- INVOICE CACHE ---
      t.integer :invoices_cache_version, default: 0

      # --- PAYMENT CACHE ---
      t.integer :payments_cache_version, default: 0

      # --- FACILITY GROUP CACHE ---
      t.integer :facility_groups_cache_version, default: 0

      # --- FACILITY CACHE ---
      t.integer :facilities_cache_version, default: 0

      # --- PROJECT GROUP CACHE ---
      t.integer :project_groups_cache_version, default: 0

      # --- PROJECT CACHE ---
      t.integer :projects_cache_version, default: 0

      # --- TASK GROUP CACHE ---
      t.integer :task_groups_cache_version, default: 0

      # --- TASK CACHE ---
      t.integer :tasks_cache_version, default: 0

      # --- BOOKING CACHE ---
      t.integer :bookings_cache_version, default: 0

      # --- MEMBERSHIP CACHE ---
      t.integer :memberships_cache_version, default: 0

      # --- RESERVATION CACHE ---
      t.integer :reservations_cache_version, default: 0

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
  end
end
