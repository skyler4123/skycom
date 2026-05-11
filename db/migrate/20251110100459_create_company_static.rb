class CreateCompanyStatic < ActiveRecord::Migration[8.0]
  def change
    create_table :company_statics, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :name

      # --- BRANCH MAPPINGS ---
      t.jsonb :branch_property_string_mappings, default: {}
      t.jsonb :branch_property_text_mappings, default: {}
      t.jsonb :branch_property_integer_mappings, default: {}
      t.jsonb :branch_property_decimal_mappings, default: {}
      t.jsonb :branch_property_boolean_mappings, default: {}
      t.jsonb :branch_property_datetime_mappings, default: {}

      # --- DEPARTMENT MAPPINGS ---
      t.jsonb :department_property_string_mappings, default: {}
      t.jsonb :department_property_text_mappings, default: {}
      t.jsonb :department_property_integer_mappings, default: {}
      t.jsonb :department_property_decimal_mappings, default: {}
      t.jsonb :department_property_boolean_mappings, default: {}
      t.jsonb :department_property_datetime_mappings, default: {}

      # --- EMPLOYEE GROUP MAPPINGS ---
      t.jsonb :employee_group_property_string_mappings, default: {}
      t.jsonb :employee_group_property_text_mappings, default: {}
      t.jsonb :employee_group_property_integer_mappings, default: {}
      t.jsonb :employee_group_property_decimal_mappings, default: {}
      t.jsonb :employee_group_property_boolean_mappings, default: {}
      t.jsonb :employee_group_property_datetime_mappings, default: {}

      # --- EMPLOYEE MAPPINGS ---
      t.jsonb :employee_property_string_mappings, default: {}
      t.jsonb :employee_property_text_mappings, default: {}
      t.jsonb :employee_property_integer_mappings, default: {}
      t.jsonb :employee_property_decimal_mappings, default: {}
      t.jsonb :employee_property_boolean_mappings, default: {}
      t.jsonb :employee_property_datetime_mappings, default: {}

      # --- CUSTOMER GROUP MAPPINGS ---
      t.jsonb :customer_group_property_string_mappings, default: {}
      t.jsonb :customer_group_property_text_mappings, default: {}
      t.jsonb :customer_group_property_integer_mappings, default: {}
      t.jsonb :customer_group_property_decimal_mappings, default: {}
      t.jsonb :customer_group_property_boolean_mappings, default: {}
      t.jsonb :customer_group_property_datetime_mappings, default: {}

      # --- CUSTOMER MAPPINGS ---
      t.jsonb :customer_property_string_mappings, default: {}
      t.jsonb :customer_property_text_mappings, default: {}
      t.jsonb :customer_property_integer_mappings, default: {}
      t.jsonb :customer_property_decimal_mappings, default: {}
      t.jsonb :customer_property_boolean_mappings, default: {}
      t.jsonb :customer_property_datetime_mappings, default: {}

      # --- BRAND MAPPINGS ---
      t.jsonb :brand_property_string_mappings, default: {}
      t.jsonb :brand_property_text_mappings, default: {}
      t.jsonb :brand_property_integer_mappings, default: {}
      t.jsonb :brand_property_decimal_mappings, default: {}
      t.jsonb :brand_property_boolean_mappings, default: {}
      t.jsonb :brand_property_datetime_mappings, default: {}

      # --- PRODUCT GROUP MAPPINGS ---
      t.jsonb :product_group_property_string_mappings, default: {}
      t.jsonb :product_group_property_text_mappings, default: {}
      t.jsonb :product_group_property_integer_mappings, default: {}
      t.jsonb :product_group_property_decimal_mappings, default: {}
      t.jsonb :product_group_property_boolean_mappings, default: {}
      t.jsonb :product_group_property_datetime_mappings, default: {}

      # --- PRODUCT MAPPINGS ---
      t.jsonb :product_property_string_mappings, default: {}
      t.jsonb :product_property_text_mappings, default: {}
      t.jsonb :product_property_integer_mappings, default: {}
      t.jsonb :product_property_decimal_mappings, default: {}
      t.jsonb :product_property_boolean_mappings, default: {}
      t.jsonb :product_property_datetime_mappings, default: {}

      # --- WAREHOUSE MAPPINGS ---
      t.jsonb :warehouse_property_string_mappings, default: {}
      t.jsonb :warehouse_property_text_mappings, default: {}
      t.jsonb :warehouse_property_integer_mappings, default: {}
      t.jsonb :warehouse_property_decimal_mappings, default: {}
      t.jsonb :warehouse_property_boolean_mappings, default: {}
      t.jsonb :warehouse_property_datetime_mappings, default: {}

      # --- STOCK MAPPINGS ---
      t.jsonb :stock_property_string_mappings, default: {}
      t.jsonb :stock_property_text_mappings, default: {}
      t.jsonb :stock_property_integer_mappings, default: {}
      t.jsonb :stock_property_decimal_mappings, default: {}
      t.jsonb :stock_property_boolean_mappings, default: {}
      t.jsonb :stock_property_datetime_mappings, default: {}

      # --- STOCK TRANSFER MAPPINGS ---
      t.jsonb :stock_transfer_property_string_mappings, default: {}
      t.jsonb :stock_transfer_property_text_mappings, default: {}
      t.jsonb :stock_transfer_property_integer_mappings, default: {}
      t.jsonb :stock_transfer_property_decimal_mappings, default: {}
      t.jsonb :stock_transfer_property_boolean_mappings, default: {}
      t.jsonb :stock_transfer_property_datetime_mappings, default: {}

      # --- STOCK IMPORT MAPPINGS ---
      t.jsonb :stock_import_property_string_mappings, default: {}
      t.jsonb :stock_import_property_text_mappings, default: {}
      t.jsonb :stock_import_property_integer_mappings, default: {}
      t.jsonb :stock_import_property_decimal_mappings, default: {}
      t.jsonb :stock_import_property_boolean_mappings, default: {}
      t.jsonb :stock_import_property_datetime_mappings, default: {}

      # --- STOCK EXPORT MAPPINGS ---
      t.jsonb :stock_export_property_string_mappings, default: {}
      t.jsonb :stock_export_property_text_mappings, default: {}
      t.jsonb :stock_export_property_integer_mappings, default: {}
      t.jsonb :stock_export_property_decimal_mappings, default: {}
      t.jsonb :stock_export_property_boolean_mappings, default: {}
      t.jsonb :stock_export_property_datetime_mappings, default: {}

      # --- SERVICE GROUP MAPPINGS ---
      t.jsonb :service_group_property_string_mappings, default: {}
      t.jsonb :service_group_property_text_mappings, default: {}
      t.jsonb :service_group_property_integer_mappings, default: {}
      t.jsonb :service_group_property_decimal_mappings, default: {}
      t.jsonb :service_group_property_boolean_mappings, default: {}
      t.jsonb :service_group_property_datetime_mappings, default: {}

      # --- SERVICE MAPPINGS ---
      t.jsonb :service_property_string_mappings, default: {}
      t.jsonb :service_property_text_mappings, default: {}
      t.jsonb :service_property_integer_mappings, default: {}
      t.jsonb :service_property_decimal_mappings, default: {}
      t.jsonb :service_property_boolean_mappings, default: {}
      t.jsonb :service_property_datetime_mappings, default: {}

      # --- ORDER GROUP MAPPINGS ---
      t.jsonb :order_group_property_string_mappings, default: {}
      t.jsonb :order_group_property_text_mappings, default: {}
      t.jsonb :order_group_property_integer_mappings, default: {}
      t.jsonb :order_group_property_decimal_mappings, default: {}
      t.jsonb :order_group_property_boolean_mappings, default: {}
      t.jsonb :order_group_property_datetime_mappings, default: {}

      # --- ORDER MAPPINGS ---
      t.jsonb :order_property_string_mappings, default: {}
      t.jsonb :order_property_text_mappings, default: {}
      t.jsonb :order_property_integer_mappings, default: {}
      t.jsonb :order_property_decimal_mappings, default: {}
      t.jsonb :order_property_boolean_mappings, default: {}
      t.jsonb :order_property_datetime_mappings, default: {}

      # --- CART GROUP MAPPINGS ---
      t.jsonb :cart_group_property_string_mappings, default: {}
      t.jsonb :cart_group_property_text_mappings, default: {}
      t.jsonb :cart_group_property_integer_mappings, default: {}
      t.jsonb :cart_group_property_decimal_mappings, default: {}
      t.jsonb :cart_group_property_boolean_mappings, default: {}
      t.jsonb :cart_group_property_datetime_mappings, default: {}

      # --- CART MAPPINGS ---
      t.jsonb :cart_property_string_mappings, default: {}
      t.jsonb :cart_property_text_mappings, default: {}
      t.jsonb :cart_property_integer_mappings, default: {}
      t.jsonb :cart_property_decimal_mappings, default: {}
      t.jsonb :cart_property_boolean_mappings, default: {}
      t.jsonb :cart_property_datetime_mappings, default: {}

      # --- PURCHASE MAPPINGS ---
      t.jsonb :purchase_property_string_mappings, default: {}
      t.jsonb :purchase_property_text_mappings, default: {}
      t.jsonb :purchase_property_integer_mappings, default: {}
      t.jsonb :purchase_property_decimal_mappings, default: {}
      t.jsonb :purchase_property_boolean_mappings, default: {}
      t.jsonb :purchase_property_datetime_mappings, default: {}

      # --- PURCHASE ITEM MAPPINGS ---
      t.jsonb :purchase_item_property_string_mappings, default: {}
      t.jsonb :purchase_item_property_text_mappings, default: {}
      t.jsonb :purchase_item_property_integer_mappings, default: {}
      t.jsonb :purchase_item_property_decimal_mappings, default: {}
      t.jsonb :purchase_item_property_boolean_mappings, default: {}
      t.jsonb :purchase_item_property_datetime_mappings, default: {}

      # --- INVOICE MAPPINGS ---
      t.jsonb :invoice_property_string_mappings, default: {}
      t.jsonb :invoice_property_text_mappings, default: {}
      t.jsonb :invoice_property_integer_mappings, default: {}
      t.jsonb :invoice_property_decimal_mappings, default: {}
      t.jsonb :invoice_property_boolean_mappings, default: {}
      t.jsonb :invoice_property_datetime_mappings, default: {}

      # --- PAYMENT MAPPINGS ---
      t.jsonb :payment_property_string_mappings, default: {}
      t.jsonb :payment_property_text_mappings, default: {}
      t.jsonb :payment_property_integer_mappings, default: {}
      t.jsonb :payment_property_decimal_mappings, default: {}
      t.jsonb :payment_property_boolean_mappings, default: {}
      t.jsonb :payment_property_datetime_mappings, default: {}

      # --- FACILITY GROUP MAPPINGS ---
      t.jsonb :facility_group_property_string_mappings, default: {}
      t.jsonb :facility_group_property_text_mappings, default: {}
      t.jsonb :facility_group_property_integer_mappings, default: {}
      t.jsonb :facility_group_property_decimal_mappings, default: {}
      t.jsonb :facility_group_property_boolean_mappings, default: {}
      t.jsonb :facility_group_property_datetime_mappings, default: {}

      # --- FACILITY MAPPINGS ---
      t.jsonb :facility_property_string_mappings, default: {}
      t.jsonb :facility_property_text_mappings, default: {}
      t.jsonb :facility_property_integer_mappings, default: {}
      t.jsonb :facility_property_decimal_mappings, default: {}
      t.jsonb :facility_property_boolean_mappings, default: {}
      t.jsonb :facility_property_datetime_mappings, default: {}

      # --- PROJECT GROUP MAPPINGS ---
      t.jsonb :project_group_property_string_mappings, default: {}
      t.jsonb :project_group_property_text_mappings, default: {}
      t.jsonb :project_group_property_integer_mappings, default: {}
      t.jsonb :project_group_property_decimal_mappings, default: {}
      t.jsonb :project_group_property_boolean_mappings, default: {}
      t.jsonb :project_group_property_datetime_mappings, default: {}

      # --- PROJECT MAPPINGS ---
      t.jsonb :project_property_string_mappings, default: {}
      t.jsonb :project_property_text_mappings, default: {}
      t.jsonb :project_property_integer_mappings, default: {}
      t.jsonb :project_property_decimal_mappings, default: {}
      t.jsonb :project_property_boolean_mappings, default: {}
      t.jsonb :project_property_datetime_mappings, default: {}

      # --- TASK GROUP MAPPINGS ---
      t.jsonb :task_group_property_string_mappings, default: {}
      t.jsonb :task_group_property_text_mappings, default: {}
      t.jsonb :task_group_property_integer_mappings, default: {}
      t.jsonb :task_group_property_decimal_mappings, default: {}
      t.jsonb :task_group_property_boolean_mappings, default: {}
      t.jsonb :task_group_property_datetime_mappings, default: {}

      # --- TASK MAPPINGS ---
      t.jsonb :task_property_string_mappings, default: {}
      t.jsonb :task_property_text_mappings, default: {}
      t.jsonb :task_property_integer_mappings, default: {}
      t.jsonb :task_property_decimal_mappings, default: {}
      t.jsonb :task_property_boolean_mappings, default: {}
      t.jsonb :task_property_datetime_mappings, default: {}

      # --- BOOKING MAPPINGS ---
      t.jsonb :booking_property_string_mappings, default: {}
      t.jsonb :booking_property_text_mappings, default: {}
      t.jsonb :booking_property_integer_mappings, default: {}
      t.jsonb :booking_property_decimal_mappings, default: {}
      t.jsonb :booking_property_boolean_mappings, default: {}
      t.jsonb :booking_property_datetime_mappings, default: {}

      # --- MEMBERSHIP MAPPINGS ---
      t.jsonb :membership_property_string_mappings, default: {}
      t.jsonb :membership_property_text_mappings, default: {}
      t.jsonb :membership_property_integer_mappings, default: {}
      t.jsonb :membership_property_decimal_mappings, default: {}
      t.jsonb :membership_property_boolean_mappings, default: {}
      t.jsonb :membership_property_datetime_mappings, default: {}

      # --- RESERVATION MAPPINGS ---
      t.jsonb :reservation_property_string_mappings, default: {}
      t.jsonb :reservation_property_text_mappings, default: {}
      t.jsonb :reservation_property_integer_mappings, default: {}
      t.jsonb :reservation_property_decimal_mappings, default: {}
      t.jsonb :reservation_property_boolean_mappings, default: {}
      t.jsonb :reservation_property_datetime_mappings, default: {}

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
