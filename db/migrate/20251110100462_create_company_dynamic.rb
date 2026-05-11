class CreateCompanyDynamic < ActiveRecord::Migration[8.0]
  def change
    create_table :company_dynamics, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- BRANCH CACHE ---
      t.integer :branch_cache_version, default: 0

      # --- DEPARTMENT CACHE ---
      t.integer :department_cache_version, default: 0

      # --- EMPLOYEE GROUP CACHE ---
      t.integer :employee_group_cache_version, default: 0

      # --- EMPLOYEE CACHE ---
      t.integer :employee_cache_version, default: 0

      # --- CUSTOMER GROUP CACHE ---
      t.integer :customer_group_cache_version, default: 0

      # --- CUSTOMER CACHE ---
      t.integer :customer_cache_version, default: 0

      # --- BRAND CACHE ---
      t.integer :brand_cache_version, default: 0

      # --- PRODUCT GROUP CACHE ---
      t.integer :product_group_cache_version, default: 0

      # --- PRODUCT CACHE ---
      t.integer :product_cache_version, default: 0

      # --- WAREHOUSE CACHE ---
      t.integer :warehouse_cache_version, default: 0

      # --- STOCK CACHE ---
      t.integer :stock_cache_version, default: 0

      # --- STOCK TRANSFER CACHE ---
      t.integer :stock_transfer_cache_version, default: 0

      # --- STOCK IMPORT CACHE ---
      t.integer :stock_import_cache_version, default: 0

      # --- STOCK EXPORT CACHE ---
      t.integer :stock_export_cache_version, default: 0

      # --- SERVICE GROUP CACHE ---
      t.integer :service_group_cache_version, default: 0

      # --- SERVICE CACHE ---
      t.integer :service_cache_version, default: 0

      # --- ORDER GROUP CACHE ---
      t.integer :order_group_cache_version, default: 0

      # --- ORDER CACHE ---
      t.integer :order_cache_version, default: 0

      # --- CART GROUP CACHE ---
      t.integer :cart_group_cache_version, default: 0

      # --- CART CACHE ---
      t.integer :cart_cache_version, default: 0

      # --- PURCHASE CACHE ---
      t.integer :purchase_cache_version, default: 0

      # --- PURCHASE ITEM CACHE ---
      t.integer :purchase_item_cache_version, default: 0

      # --- INVOICE CACHE ---
      t.integer :invoice_cache_version, default: 0

      # --- PAYMENT CACHE ---
      t.integer :payment_cache_version, default: 0

      # --- FACILITY GROUP CACHE ---
      t.integer :facility_group_cache_version, default: 0

      # --- FACILITY CACHE ---
      t.integer :facility_cache_version, default: 0

      # --- PROJECT GROUP CACHE ---
      t.integer :project_group_cache_version, default: 0

      # --- PROJECT CACHE ---
      t.integer :project_cache_version, default: 0

      # --- TASK GROUP CACHE ---
      t.integer :task_group_cache_version, default: 0

      # --- TASK CACHE ---
      t.integer :task_cache_version, default: 0

      # --- BOOKING CACHE ---
      t.integer :booking_cache_version, default: 0

      # --- MEMBERSHIP CACHE ---
      t.integer :membership_cache_version, default: 0

      # --- RESERVATION CACHE ---
      t.integer :reservation_cache_version, default: 0

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
