class CreateCachedVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :cached_versions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- BRANCH CACHE ---
      t.integer :branches_cached_version, default: 0

      # --- DEPARTMENT CACHE ---
      t.integer :departments_cached_version, default: 0

      # --- EMPLOYEE GROUP CACHE ---
      t.integer :employee_groups_cached_version, default: 0

      # --- EMPLOYEE CACHE ---
      t.integer :employees_cached_version, default: 0

      # --- CUSTOMER GROUP CACHE ---
      t.integer :customer_groups_cached_version, default: 0

      # --- CUSTOMER CACHE ---
      t.integer :customers_cached_version, default: 0

      # --- BRAND CACHE ---
      t.integer :brands_cached_version, default: 0

      # --- PRODUCT GROUP CACHE ---
      t.integer :product_groups_cached_version, default: 0

      # --- PRODUCT CACHE ---
      t.integer :products_cached_version, default: 0

      # --- WAREHOUSE CACHE ---
      t.integer :warehouses_cached_version, default: 0

      # --- STOCK CACHE ---
      t.integer :stocks_cached_version, default: 0

      # --- STOCK TRANSFER CACHE ---
      t.integer :stock_transfers_cached_version, default: 0

      # --- STOCK IMPORT CACHE ---
      t.integer :stock_imports_cached_version, default: 0

      # --- STOCK EXPORT CACHE ---
      t.integer :stock_exports_cached_version, default: 0

      # --- SERVICE GROUP CACHE ---
      t.integer :service_groups_cached_version, default: 0

      # --- SERVICE CACHE ---
      t.integer :services_cached_version, default: 0

      # --- ORDER GROUP CACHE ---
      t.integer :order_groups_cached_version, default: 0

      # --- ORDER CACHE ---
      t.integer :orders_cached_version, default: 0

      # --- CART GROUP CACHE ---
      t.integer :cart_groups_cached_version, default: 0

      # --- CART CACHE ---
      t.integer :carts_cached_version, default: 0

      # --- PURCHASE CACHE ---
      t.integer :purchases_cached_version, default: 0

      # --- PURCHASE ITEM CACHE ---
      t.integer :purchase_items_cached_version, default: 0

      # --- INVOICE CACHE ---
      t.integer :invoices_cached_version, default: 0

      # --- PAYMENT CACHE ---
      t.integer :payments_cached_version, default: 0

      # --- FACILITY GROUP CACHE ---
      t.integer :facility_groups_cached_version, default: 0

      # --- FACILITY CACHE ---
      t.integer :facilities_cached_version, default: 0

      # --- PROJECT GROUP CACHE ---
      t.integer :project_groups_cached_version, default: 0

      # --- PROJECT CACHE ---
      t.integer :projects_cached_version, default: 0

      # --- TASK GROUP CACHE ---
      t.integer :task_groups_cached_version, default: 0

      # --- TASK CACHE ---
      t.integer :tasks_cached_version, default: 0

      # --- BOOKING CACHE ---
      t.integer :bookings_cached_version, default: 0

      # --- MEMBERSHIP CACHE ---
      t.integer :memberships_cached_version, default: 0

      # --- RESERVATION CACHE ---
      t.integer :reservations_cached_version, default: 0

      t.timestamps
    end
  end
end
