# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_18_070745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "address_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "address_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "value"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_appointments_on_address_id"
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_address_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_address_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_address_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_9dbaa804bc"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_address_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_address_appointments_on_business_type"
    t.index ["discarded_at"], name: "index_address_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_address_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_appointments_on_workflow_status"
  end

  create_table "addresses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "line_1", null: false
    t.string "line_2"
    t.string "city", null: false
    t.string "state_or_province"
    t.string "postal_code"
    t.integer "country"
    t.string "fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fingerprint"], name: "index_addresses_on_fingerprint", unique: true
  end

  create_table "answers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "question_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_answers_on_business_type"
    t.index ["category_id"], name: "index_answers_on_category_id"
    t.index ["company_id"], name: "index_answers_on_company_id"
    t.index ["discarded_at"], name: "index_answers_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_answers_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_answers_on_property_mapping_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["workflow_status"], name: "index_answers_on_workflow_status"
  end

  create_table "article_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "article_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_article_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_article_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_article_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_aae71362ee"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_article_appointments_on_appoint_to"
    t.index ["article_id"], name: "index_article_appointments_on_article_id"
    t.index ["business_type"], name: "index_article_appointments_on_business_type"
    t.index ["company_id"], name: "index_article_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_article_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_article_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_article_appointments_on_workflow_status"
  end

  create_table "article_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "article_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_article_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_article_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_article_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_3810e29801"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_article_group_appointments_on_appoint_to"
    t.index ["article_group_id"], name: "index_article_group_appointments_on_article_group_id"
    t.index ["business_type"], name: "index_article_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_article_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_article_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_article_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_article_group_appointments_on_workflow_status"
  end

  create_table "article_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "title"
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_article_groups_on_branch_id"
    t.index ["business_type"], name: "index_article_groups_on_business_type"
    t.index ["category_id"], name: "index_article_groups_on_category_id"
    t.index ["company_id"], name: "index_article_groups_on_company_id"
    t.index ["discarded_at"], name: "index_article_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_article_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_article_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_article_groups_on_workflow_status"
  end

  create_table "articles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "article_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "title"
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_group_id"], name: "index_articles_on_article_group_id"
    t.index ["branch_id"], name: "index_articles_on_branch_id"
    t.index ["business_type"], name: "index_articles_on_business_type"
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["company_id"], name: "index_articles_on_company_id"
    t.index ["discarded_at"], name: "index_articles_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_articles_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_articles_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_articles_on_workflow_status"
  end

  create_table "attendance_days", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.date "attendance_date", null: false
    t.datetime "check_in"
    t.datetime "check_out"
    t.datetime "break_start"
    t.datetime "break_end"
    t.integer "total_seconds_present"
    t.integer "total_seconds_break"
    t.integer "total_seconds_worked"
    t.integer "total_seconds_overtime"
    t.integer "attendance_status"
    t.integer "recorded_method"
    t.text "notes"
    t.string "approved_by_type"
    t.uuid "approved_by_id"
    t.datetime "approved_at"
    t.string "edited_by_type"
    t.uuid "edited_by_id"
    t.datetime "edited_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_days_on_branch_id"
    t.index ["company_id"], name: "index_attendance_days_on_company_id"
    t.index ["discarded_at"], name: "index_attendance_days_on_discarded_at"
    t.index ["employee_id"], name: "index_attendance_days_on_employee_id"
  end

  create_table "attendance_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.integer "log_type", null: false
    t.datetime "logged_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "wifi_ssid"
    t.string "device_fingerprint"
    t.string "photo_url"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_logs_on_branch_id"
    t.index ["company_id"], name: "index_attendance_logs_on_company_id"
    t.index ["discarded_at"], name: "index_attendance_logs_on_discarded_at"
    t.index ["employee_id"], name: "index_attendance_logs_on_employee_id"
  end

  create_table "attendance_months", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.date "month", null: false
    t.integer "total_work_minutes"
    t.integer "total_late_minutes"
    t.integer "total_early_leave_minutes"
    t.integer "total_overtime_minutes"
    t.integer "total_absent_days"
    t.integer "total_present_days"
    t.integer "total_records"
    t.integer "total_deficit_minutes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_months_on_branch_id"
    t.index ["company_id"], name: "index_attendance_months_on_company_id"
    t.index ["discarded_at"], name: "index_attendance_months_on_discarded_at"
    t.index ["employee_id", "month"], name: "index_attendance_months_on_employee_id_and_month", unique: true
    t.index ["employee_id"], name: "index_attendance_months_on_employee_id"
  end

  create_table "attendance_policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.integer "allowed_radius_meters", null: false
    t.string "allowed_wifi_ssid"
    t.boolean "require_photo", null: false
    t.integer "resolution_strategy", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_policies_on_branch_id", unique: true
    t.index ["company_id"], name: "index_attendance_policies_on_company_id"
    t.index ["discarded_at"], name: "index_attendance_policies_on_discarded_at"
  end

  create_table "billing_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "description"
    t.integer "contract_type", null: false
    t.integer "fixed_monthly_price_cents", null: false
    t.integer "currency", null: false
    t.datetime "start_date", null: false
    t.datetime "end_time"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_billing_contracts_on_company_id"
    t.index ["lifecycle_status"], name: "index_billing_contracts_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_billing_contracts_on_workflow_status"
  end

  create_table "billing_invoices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "billing_contract_id", null: false
    t.string "name"
    t.text "description"
    t.string "invoice_number", null: false
    t.integer "movement_type"
    t.integer "target_balance"
    t.integer "created_by"
    t.integer "price_cents", null: false
    t.integer "currency", null: false
    t.datetime "period_start", null: false
    t.datetime "period_end", null: false
    t.datetime "due_at"
    t.integer "payment_status"
    t.integer "lifecycle_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_contract_id"], name: "index_billing_invoices_on_billing_contract_id"
    t.index ["company_id"], name: "index_billing_invoices_on_company_id"
    t.index ["created_by"], name: "index_billing_invoices_on_created_by"
    t.index ["invoice_number"], name: "index_billing_invoices_on_invoice_number"
    t.index ["lifecycle_status"], name: "index_billing_invoices_on_lifecycle_status"
    t.index ["movement_type"], name: "index_billing_invoices_on_movement_type"
    t.index ["payment_status"], name: "index_billing_invoices_on_payment_status"
    t.index ["target_balance"], name: "index_billing_invoices_on_target_balance"
  end

  create_table "billing_payment_methods", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.integer "strategy"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "payment_mode"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_billing_payment_methods_on_business_type"
    t.index ["code"], name: "index_billing_payment_methods_on_code", unique: true
    t.index ["discarded_at"], name: "index_billing_payment_methods_on_discarded_at"
    t.index ["email"], name: "index_billing_payment_methods_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_billing_payment_methods_on_lifecycle_status"
    t.index ["payment_mode"], name: "index_billing_payment_methods_on_payment_mode"
    t.index ["workflow_status"], name: "index_billing_payment_methods_on_workflow_status"
  end

  create_table "billing_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "resource_type", null: false
    t.integer "country"
    t.integer "price_cents", null: false
    t.integer "currency", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lifecycle_status"], name: "index_billing_resources_on_lifecycle_status"
    t.index ["name", "country"], name: "index_billing_resources_on_name_and_country", unique: true
    t.index ["workflow_status"], name: "index_billing_resources_on_workflow_status"
  end

  create_table "billing_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "billing_invoice_id", null: false
    t.uuid "billing_payment_method_id", null: false
    t.integer "transaction_type", null: false
    t.integer "amount_cents", null: false
    t.integer "currency", null: false
    t.integer "balance_before_cents", null: false
    t.integer "balance_after_cents", null: false
    t.integer "promo_balance_before_cents", null: false
    t.integer "promo_balance_after_cents", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.string "gateway_reference"
    t.jsonb "gateway_payload", default: {}
    t.index ["billing_invoice_id"], name: "index_billing_transactions_on_billing_invoice_id"
    t.index ["billing_payment_method_id"], name: "index_billing_transactions_on_billing_payment_method_id"
    t.index ["company_id", "created_at"], name: "idx_wallet_tx_company_chrono"
    t.index ["company_id"], name: "index_billing_transactions_on_company_id"
    t.index ["gateway_reference"], name: "index_billing_transactions_on_gateway_reference", unique: true
    t.index ["status"], name: "index_billing_transactions_on_status"
  end

  create_table "billing_wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "country"
    t.integer "currency", null: false
    t.integer "promo_balance_cents", null: false
    t.integer "main_balance_cents", null: false
    t.integer "soft_debt_threshold_cents", null: false
    t.datetime "suspension_at"
    t.boolean "hide_billing_alerts", null: false
    t.datetime "has_unpaid_invoices_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_billing_wallets_on_business_type"
    t.index ["company_id"], name: "index_billing_wallets_on_company_id"
    t.index ["discarded_at"], name: "index_billing_wallets_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_billing_wallets_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_billing_wallets_on_workflow_status"
  end

  create_table "branches", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.uuid "parent_branch_id"
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_branches_on_business_type"
    t.index ["category_id"], name: "index_branches_on_category_id"
    t.index ["code"], name: "index_branches_on_code", unique: true
    t.index ["company_id"], name: "index_branches_on_company_id"
    t.index ["discarded_at"], name: "index_branches_on_discarded_at"
    t.index ["email"], name: "index_branches_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_branches_on_lifecycle_status"
    t.index ["parent_branch_id"], name: "index_branches_on_parent_branch_id"
    t.index ["property_mapping_id"], name: "index_branches_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_branches_on_workflow_status"
  end

  create_table "brands", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_brands_on_business_type"
    t.index ["category_id"], name: "index_brands_on_category_id"
    t.index ["code"], name: "index_brands_on_code", unique: true
    t.index ["company_id"], name: "index_brands_on_company_id"
    t.index ["discarded_at"], name: "index_brands_on_discarded_at"
    t.index ["email"], name: "index_brands_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_brands_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_brands_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_brands_on_workflow_status"
  end

  create_table "cart_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "cart_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_cart_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_cart_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_cart_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_cart_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_cart_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_cart_appointments_on_business_type"
    t.index ["cart_id"], name: "index_cart_appointments_on_cart_id"
    t.index ["company_id"], name: "index_cart_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_cart_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_cart_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_cart_appointments_on_workflow_status"
  end

  create_table "cart_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_cart_groups_on_branch_id"
    t.index ["business_type"], name: "index_cart_groups_on_business_type"
    t.index ["category_id"], name: "index_cart_groups_on_category_id"
    t.index ["code"], name: "index_cart_groups_on_code", unique: true
    t.index ["company_id"], name: "index_cart_groups_on_company_id"
    t.index ["discarded_at"], name: "index_cart_groups_on_discarded_at"
    t.index ["email"], name: "index_cart_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_cart_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_cart_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_cart_groups_on_workflow_status"
  end

  create_table "carts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "cart_group_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_carts_on_branch_id"
    t.index ["business_type"], name: "index_carts_on_business_type"
    t.index ["cart_group_id"], name: "index_carts_on_cart_group_id"
    t.index ["category_id"], name: "index_carts_on_category_id"
    t.index ["code"], name: "index_carts_on_code", unique: true
    t.index ["company_id"], name: "index_carts_on_company_id"
    t.index ["discarded_at"], name: "index_carts_on_discarded_at"
    t.index ["email"], name: "index_carts_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_carts_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_carts_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_carts_on_workflow_status"
  end

  create_table "categories", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_categories_on_business_type"
    t.index ["company_id", "name"], name: "index_categories_on_company_id_and_name"
    t.index ["company_id"], name: "index_categories_on_company_id"
    t.index ["discarded_at"], name: "index_categories_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_categories_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_categories_on_workflow_status"
  end

  create_table "companies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "ownership_type"
    t.integer "currency"
    t.string "registration_number"
    t.string "vat_id"
    t.string "tax_id"
    t.integer "timezone"
    t.string "address_line_1"
    t.string "city"
    t.string "postal_code"
    t.integer "country"
    t.string "email"
    t.string "phone_number"
    t.string "website"
    t.integer "employee_count"
    t.integer "fiscal_year_end_month"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_companies_on_business_type"
    t.index ["discarded_at"], name: "index_companies_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_companies_on_lifecycle_status"
    t.index ["user_id"], name: "index_companies_on_user_id"
    t.index ["workflow_status"], name: "index_companies_on_workflow_status"
  end

  create_table "contract_features", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "billing_resource_id", null: false
    t.uuid "billing_contract_id", null: false
    t.string "name"
    t.string "description"
    t.integer "monthly_flat_price_cents", null: false
    t.integer "price_cents"
    t.integer "currency", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_contract_id", "billing_resource_id"], name: "index_contract_features_on_contract_and_resource", unique: true
    t.index ["billing_contract_id"], name: "index_contract_features_on_billing_contract_id"
    t.index ["billing_resource_id"], name: "index_contract_features_on_billing_resource_id"
    t.index ["lifecycle_status"], name: "index_contract_features_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_contract_features_on_workflow_status"
  end

  create_table "contract_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "billing_resource_id", null: false
    t.uuid "billing_contract_id", null: false
    t.string "name"
    t.string "description"
    t.integer "free_allowance", null: false
    t.integer "unit_price_cents", null: false
    t.integer "currency", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_contract_id", "billing_resource_id"], name: "index_contract_metrics_on_contract_and_resource", unique: true
    t.index ["billing_contract_id"], name: "index_contract_metrics_on_billing_contract_id"
    t.index ["billing_resource_id"], name: "index_contract_metrics_on_billing_resource_id"
    t.index ["lifecycle_status"], name: "index_contract_metrics_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_contract_metrics_on_workflow_status"
  end

  create_table "customer_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_customer_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_customer_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_customer_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_1b496b2c03"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_customer_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_customer_appointments_on_business_type"
    t.index ["company_id"], name: "index_customer_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_customer_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_customer_appointments_on_workflow_status"
  end

  create_table "customer_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_customer_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_customer_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_customer_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_a6c19edb35"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_customer_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_customer_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_customer_group_appointments_on_company_id"
    t.index ["customer_group_id"], name: "index_customer_group_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_customer_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_customer_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_customer_group_appointments_on_workflow_status"
  end

  create_table "customer_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_customer_groups_on_branch_id"
    t.index ["business_type"], name: "index_customer_groups_on_business_type"
    t.index ["category_id"], name: "index_customer_groups_on_category_id"
    t.index ["code"], name: "index_customer_groups_on_code", unique: true
    t.index ["company_id"], name: "index_customer_groups_on_company_id"
    t.index ["discarded_at"], name: "index_customer_groups_on_discarded_at"
    t.index ["email"], name: "index_customer_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_customer_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_customer_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_customer_groups_on_workflow_status"
  end

  create_table "customers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "user_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_customers_on_branch_id"
    t.index ["business_type"], name: "index_customers_on_business_type"
    t.index ["category_id"], name: "index_customers_on_category_id"
    t.index ["code"], name: "index_customers_on_code", unique: true
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_customers_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_customers_on_property_mapping_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
    t.index ["workflow_status"], name: "index_customers_on_workflow_status"
  end

  create_table "daily_feature_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "contract_feature_id", null: false
    t.date "log_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "contract_feature_id", "log_date"], name: "idx_daily_feature_logs_unique", unique: true
    t.index ["company_id"], name: "index_daily_feature_logs_on_company_id"
    t.index ["contract_feature_id"], name: "index_daily_feature_logs_on_contract_feature_id"
    t.index ["log_date"], name: "index_daily_feature_logs_on_log_date"
  end

  create_table "daily_metric_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "billing_resource_id", null: false
    t.integer "usage_count", null: false
    t.date "log_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_resource_id"], name: "index_daily_metric_logs_on_billing_resource_id"
    t.index ["company_id", "billing_resource_id", "log_date"], name: "idx_daily_metric_lookup"
    t.index ["company_id"], name: "index_daily_metric_logs_on_company_id"
  end

  create_table "department_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "department_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_department_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_department_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_department_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_8ea813e354"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_department_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_department_appointments_on_business_type"
    t.index ["company_id"], name: "index_department_appointments_on_company_id"
    t.index ["department_id"], name: "index_department_appointments_on_department_id"
    t.index ["discarded_at"], name: "index_department_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_department_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_department_appointments_on_workflow_status"
  end

  create_table "departments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_departments_on_business_type"
    t.index ["category_id"], name: "index_departments_on_category_id"
    t.index ["code"], name: "index_departments_on_code", unique: true
    t.index ["company_id"], name: "index_departments_on_company_id"
    t.index ["discarded_at"], name: "index_departments_on_discarded_at"
    t.index ["email"], name: "index_departments_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_departments_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_departments_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_departments_on_workflow_status"
  end

  create_table "document_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "document_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_document_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_document_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_document_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_fcaa395aab"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_document_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_document_appointments_on_business_type"
    t.index ["company_id"], name: "index_document_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_document_appointments_on_discarded_at"
    t.index ["document_id"], name: "index_document_appointments_on_document_id"
    t.index ["lifecycle_status"], name: "index_document_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_document_appointments_on_workflow_status"
  end

  create_table "document_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "document_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_document_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_document_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_document_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_a5029e226f"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_document_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_document_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_document_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_document_group_appointments_on_discarded_at"
    t.index ["document_group_id"], name: "index_document_group_appointments_on_document_group_id"
    t.index ["lifecycle_status"], name: "index_document_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_document_group_appointments_on_workflow_status"
  end

  create_table "document_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "title"
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_document_groups_on_branch_id"
    t.index ["business_type"], name: "index_document_groups_on_business_type"
    t.index ["category_id"], name: "index_document_groups_on_category_id"
    t.index ["company_id"], name: "index_document_groups_on_company_id"
    t.index ["discarded_at"], name: "index_document_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_document_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_document_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_document_groups_on_workflow_status"
  end

  create_table "documents", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "document_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "title"
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_documents_on_branch_id"
    t.index ["business_type"], name: "index_documents_on_business_type"
    t.index ["category_id"], name: "index_documents_on_category_id"
    t.index ["company_id"], name: "index_documents_on_company_id"
    t.index ["discarded_at"], name: "index_documents_on_discarded_at"
    t.index ["document_group_id"], name: "index_documents_on_document_group_id"
    t.index ["lifecycle_status"], name: "index_documents_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_documents_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_documents_on_workflow_status"
  end

  create_table "employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "permission_resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_employee_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_employee_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_employee_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_a39c78be55"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_employee_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_employee_appointments_on_business_type"
    t.index ["company_id"], name: "index_employee_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_appointments_on_employee_id"
    t.index ["lifecycle_status"], name: "index_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_appointments_on_workflow_status"
  end

  create_table "employee_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "permission_resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_employee_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_employee_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_employee_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_57b6eaae20"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_employee_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_employee_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_employee_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_group_appointments_on_discarded_at"
    t.index ["employee_group_id"], name: "index_employee_group_appointments_on_employee_group_id"
    t.index ["lifecycle_status"], name: "index_employee_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_group_appointments_on_workflow_status"
  end

  create_table "employee_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_employee_groups_on_branch_id"
    t.index ["business_type"], name: "index_employee_groups_on_business_type"
    t.index ["category_id"], name: "index_employee_groups_on_category_id"
    t.index ["code"], name: "index_employee_groups_on_code", unique: true
    t.index ["company_id"], name: "index_employee_groups_on_company_id"
    t.index ["discarded_at"], name: "index_employee_groups_on_discarded_at"
    t.index ["email"], name: "index_employee_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_employee_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_employee_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_employee_groups_on_workflow_status"
  end

  create_table "employees", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "user_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_employees_on_branch_id"
    t.index ["business_type"], name: "index_employees_on_business_type"
    t.index ["category_id"], name: "index_employees_on_category_id"
    t.index ["code"], name: "index_employees_on_code", unique: true
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["discarded_at"], name: "index_employees_on_discarded_at"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_employees_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_employees_on_property_mapping_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
    t.index ["workflow_status"], name: "index_employees_on_workflow_status"
  end

  create_table "event_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_event_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_event_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_event_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_event_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_event_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_event_appointments_on_business_type"
    t.index ["company_id"], name: "index_event_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_appointments_on_event_id"
    t.index ["lifecycle_status"], name: "index_event_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_event_appointments_on_workflow_status"
  end

  create_table "event_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_event_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_event_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_event_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_941fb608a2"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_event_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_event_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_event_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_group_appointments_on_discarded_at"
    t.index ["event_group_id"], name: "index_event_group_appointments_on_event_group_id"
    t.index ["lifecycle_status"], name: "index_event_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_event_group_appointments_on_workflow_status"
  end

  create_table "event_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_event_groups_on_branch_id"
    t.index ["business_type"], name: "index_event_groups_on_business_type"
    t.index ["category_id"], name: "index_event_groups_on_category_id"
    t.index ["company_id"], name: "index_event_groups_on_company_id"
    t.index ["discarded_at"], name: "index_event_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_event_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_event_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_event_groups_on_workflow_status"
  end

  create_table "events", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "event_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_events_on_branch_id"
    t.index ["business_type"], name: "index_events_on_business_type"
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
    t.index ["lifecycle_status"], name: "index_events_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_events_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_events_on_workflow_status"
  end

  create_table "exam_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "exam_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_exam_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_exam_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_exam_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_exam_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_exam_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_exam_appointments_on_business_type"
    t.index ["company_id"], name: "index_exam_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_exam_appointments_on_discarded_at"
    t.index ["exam_id"], name: "index_exam_appointments_on_exam_id"
    t.index ["lifecycle_status"], name: "index_exam_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_exam_appointments_on_workflow_status"
  end

  create_table "exam_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_exam_groups_on_branch_id"
    t.index ["business_type"], name: "index_exam_groups_on_business_type"
    t.index ["category_id"], name: "index_exam_groups_on_category_id"
    t.index ["company_id"], name: "index_exam_groups_on_company_id"
    t.index ["discarded_at"], name: "index_exam_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_exam_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_exam_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_exam_groups_on_workflow_status"
  end

  create_table "exams", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "exam_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_exams_on_branch_id"
    t.index ["business_type"], name: "index_exams_on_business_type"
    t.index ["category_id"], name: "index_exams_on_category_id"
    t.index ["company_id"], name: "index_exams_on_company_id"
    t.index ["discarded_at"], name: "index_exams_on_discarded_at"
    t.index ["exam_group_id"], name: "index_exams_on_exam_group_id"
    t.index ["lifecycle_status"], name: "index_exams_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_exams_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_exams_on_workflow_status"
  end

  create_table "facilities", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_facilities_on_branch_id"
    t.index ["business_type"], name: "index_facilities_on_business_type"
    t.index ["category_id"], name: "index_facilities_on_category_id"
    t.index ["code"], name: "index_facilities_on_code", unique: true
    t.index ["company_id"], name: "index_facilities_on_company_id"
    t.index ["discarded_at"], name: "index_facilities_on_discarded_at"
    t.index ["email"], name: "index_facilities_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_facilities_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_facilities_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_facilities_on_workflow_status"
  end

  create_table "facility_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_facility_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_facility_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_facility_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_b7dff614b7"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_facility_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_facility_appointments_on_business_type"
    t.index ["company_id"], name: "index_facility_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_facility_appointments_on_discarded_at"
    t.index ["facility_id"], name: "index_facility_appointments_on_facility_id"
    t.index ["lifecycle_status"], name: "index_facility_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_facility_appointments_on_workflow_status"
  end

  create_table "facility_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_facility_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_facility_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_facility_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_ebef229bea"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_facility_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_facility_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_facility_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_facility_group_appointments_on_discarded_at"
    t.index ["facility_group_id"], name: "index_facility_group_appointments_on_facility_group_id"
    t.index ["lifecycle_status"], name: "index_facility_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_facility_group_appointments_on_workflow_status"
  end

  create_table "facility_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_facility_groups_on_branch_id"
    t.index ["business_type"], name: "index_facility_groups_on_business_type"
    t.index ["category_id"], name: "index_facility_groups_on_category_id"
    t.index ["code"], name: "index_facility_groups_on_code", unique: true
    t.index ["company_id"], name: "index_facility_groups_on_company_id"
    t.index ["discarded_at"], name: "index_facility_groups_on_discarded_at"
    t.index ["email"], name: "index_facility_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_facility_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_facility_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_facility_groups_on_workflow_status"
  end

  create_table "invoices", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "order_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.datetime "due_date"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "payment_status", default: 0, null: false
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_invoices_on_branch_id"
    t.index ["business_type"], name: "index_invoices_on_business_type"
    t.index ["category_id"], name: "index_invoices_on_category_id"
    t.index ["code"], name: "index_invoices_on_code", unique: true
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["discarded_at"], name: "index_invoices_on_discarded_at"
    t.index ["email"], name: "index_invoices_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_invoices_on_lifecycle_status"
    t.index ["order_id"], name: "index_invoices_on_order_id"
    t.index ["property_mapping_id"], name: "index_invoices_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_invoices_on_workflow_status"
  end

  create_table "membership_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "membership_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_membership_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_membership_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_membership_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_92c11e8cbf"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_membership_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_membership_appointments_on_business_type"
    t.index ["company_id"], name: "index_membership_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_membership_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_membership_appointments_on_lifecycle_status"
    t.index ["membership_id"], name: "index_membership_appointments_on_membership_id"
    t.index ["workflow_status"], name: "index_membership_appointments_on_workflow_status"
  end

  create_table "memberships", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_memberships_on_branch_id"
    t.index ["business_type"], name: "index_memberships_on_business_type"
    t.index ["category_id"], name: "index_memberships_on_category_id"
    t.index ["code"], name: "index_memberships_on_code", unique: true
    t.index ["company_id"], name: "index_memberships_on_company_id"
    t.index ["discarded_at"], name: "index_memberships_on_discarded_at"
    t.index ["email"], name: "index_memberships_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_memberships_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_memberships_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_memberships_on_workflow_status"
  end

  create_table "notification_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "notification_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_notification_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_notification_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_notification_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_26a28b0bfc"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_notification_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_notification_appointments_on_business_type"
    t.index ["company_id"], name: "index_notification_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_notification_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_notification_appointments_on_lifecycle_status"
    t.index ["notification_id"], name: "index_notification_appointments_on_notification_id"
    t.index ["workflow_status"], name: "index_notification_appointments_on_workflow_status"
  end

  create_table "notification_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "notification_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_notification_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_notification_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_notification_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_8f6e8f37c0"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_notification_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_notification_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_notification_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_notification_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_notification_group_appointments_on_lifecycle_status"
    t.index ["notification_group_id"], name: "index_notification_group_appointments_on_notification_group_id"
    t.index ["workflow_status"], name: "index_notification_group_appointments_on_workflow_status"
  end

  create_table "notification_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_notification_groups_on_branch_id"
    t.index ["business_type"], name: "index_notification_groups_on_business_type"
    t.index ["category_id"], name: "index_notification_groups_on_category_id"
    t.index ["code"], name: "index_notification_groups_on_code", unique: true
    t.index ["company_id"], name: "index_notification_groups_on_company_id"
    t.index ["discarded_at"], name: "index_notification_groups_on_discarded_at"
    t.index ["email"], name: "index_notification_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_notification_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_notification_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_notification_groups_on_workflow_status"
  end

  create_table "notifications", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "notification_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_notifications_on_branch_id"
    t.index ["business_type"], name: "index_notifications_on_business_type"
    t.index ["category_id"], name: "index_notifications_on_category_id"
    t.index ["code"], name: "index_notifications_on_code", unique: true
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["discarded_at"], name: "index_notifications_on_discarded_at"
    t.index ["email"], name: "index_notifications_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_notifications_on_lifecycle_status"
    t.index ["notification_group_id"], name: "index_notifications_on_notification_group_id"
    t.index ["property_mapping_id"], name: "index_notifications_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_notifications_on_workflow_status"
  end

  create_table "order_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_order_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_order_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_order_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_order_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_order_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_order_appointments_on_business_type"
    t.index ["company_id"], name: "index_order_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_order_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_appointments_on_order_id"
    t.index ["workflow_status"], name: "index_order_appointments_on_workflow_status"
  end

  create_table "order_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_order_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_order_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_order_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_1438b68413"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_order_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_order_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_order_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_order_group_appointments_on_lifecycle_status"
    t.index ["order_group_id"], name: "index_order_group_appointments_on_order_group_id"
    t.index ["workflow_status"], name: "index_order_group_appointments_on_workflow_status"
  end

  create_table "order_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "customer_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_order_groups_on_branch_id"
    t.index ["business_type"], name: "index_order_groups_on_business_type"
    t.index ["category_id"], name: "index_order_groups_on_category_id"
    t.index ["code"], name: "index_order_groups_on_code", unique: true
    t.index ["company_id"], name: "index_order_groups_on_company_id"
    t.index ["customer_id"], name: "index_order_groups_on_customer_id"
    t.index ["discarded_at"], name: "index_order_groups_on_discarded_at"
    t.index ["email"], name: "index_order_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_order_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_order_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_order_groups_on_workflow_status"
  end

  create_table "orders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "customer_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_orders_on_branch_id"
    t.index ["business_type"], name: "index_orders_on_business_type"
    t.index ["category_id"], name: "index_orders_on_category_id"
    t.index ["code"], name: "index_orders_on_code", unique: true
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["email"], name: "index_orders_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_orders_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_orders_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_orders_on_workflow_status"
  end

  create_table "pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "business_type", null: false
    t.integer "target_role", null: false
    t.integer "target_resolution", null: false
    t.integer "lifecycle_status", null: false
    t.integer "workflow_status", null: false
    t.jsonb "metadata", null: false
    t.string "permission_resource_name", null: false
    t.datetime "expiration_date"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id", "target_role", "target_resolution", "code"], name: "idx_on_branch_id_target_role_target_resolution_code_6c16dc00fe", unique: true
    t.index ["branch_id"], name: "index_pages_on_branch_id"
    t.index ["business_type"], name: "index_pages_on_business_type"
    t.index ["code"], name: "index_pages_on_code", unique: true
    t.index ["company_id"], name: "index_pages_on_company_id"
    t.index ["discarded_at"], name: "index_pages_on_discarded_at"
    t.index ["email"], name: "index_pages_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_pages_on_lifecycle_status"
    t.index ["target_resolution"], name: "index_pages_on_target_resolution"
    t.index ["target_role"], name: "index_pages_on_target_role"
    t.index ["workflow_status"], name: "index_pages_on_workflow_status"
  end

  create_table "payment_method_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "payment_method_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_payment_method_appointments_on_branch_id"
    t.index ["business_type"], name: "index_payment_method_appointments_on_business_type"
    t.index ["company_id"], name: "index_payment_method_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_payment_method_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_payment_method_appointments_on_lifecycle_status"
    t.index ["payment_method_id", "company_id"], name: "idx_on_payment_method_id_company_id_8ff3d49954"
    t.index ["payment_method_id"], name: "index_payment_method_appointments_on_payment_method_id"
    t.index ["workflow_status"], name: "index_payment_method_appointments_on_workflow_status"
  end

  create_table "payment_methods", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.integer "strategy"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "payment_mode"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_payment_methods_on_business_type"
    t.index ["code"], name: "index_payment_methods_on_code", unique: true
    t.index ["discarded_at"], name: "index_payment_methods_on_discarded_at"
    t.index ["email"], name: "index_payment_methods_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_payment_methods_on_lifecycle_status"
    t.index ["payment_mode"], name: "index_payment_methods_on_payment_mode"
    t.index ["workflow_status"], name: "index_payment_methods_on_workflow_status"
  end

  create_table "policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "resource"
    t.string "action"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_policies_on_branch_id"
    t.index ["business_type"], name: "index_policies_on_business_type"
    t.index ["company_id"], name: "index_policies_on_company_id"
    t.index ["discarded_at"], name: "index_policies_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_policies_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_policies_on_workflow_status"
  end

  create_table "policy_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "policy_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_policy_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_policy_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_policy_appointments_on_business_type"
    t.index ["company_id"], name: "index_policy_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_policy_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_policy_appointments_on_lifecycle_status"
    t.index ["policy_id"], name: "index_policy_appointments_on_policy_id"
    t.index ["workflow_status"], name: "index_policy_appointments_on_workflow_status"
  end

  create_table "product_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_product_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_product_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_product_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_6dd1b90540"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_product_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_product_appointments_on_business_type"
    t.index ["company_id"], name: "index_product_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_product_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_product_appointments_on_lifecycle_status"
    t.index ["product_id"], name: "index_product_appointments_on_product_id"
    t.index ["workflow_status"], name: "index_product_appointments_on_workflow_status"
  end

  create_table "product_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_product_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_product_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_product_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_53bf3d5444"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_product_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_product_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_product_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_product_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_product_group_appointments_on_lifecycle_status"
    t.index ["product_group_id"], name: "index_product_group_appointments_on_product_group_id"
    t.index ["workflow_status"], name: "index_product_group_appointments_on_workflow_status"
  end

  create_table "product_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_product_groups_on_branch_id"
    t.index ["business_type"], name: "index_product_groups_on_business_type"
    t.index ["category_id"], name: "index_product_groups_on_category_id"
    t.index ["code"], name: "index_product_groups_on_code", unique: true
    t.index ["company_id"], name: "index_product_groups_on_company_id"
    t.index ["discarded_at"], name: "index_product_groups_on_discarded_at"
    t.index ["email"], name: "index_product_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_product_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_product_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_product_groups_on_workflow_status"
  end

  create_table "products", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "brand_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_products_on_branch_id"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["business_type"], name: "index_products_on_business_type"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["code"], name: "index_products_on_code", unique: true
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["email"], name: "index_products_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_products_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_products_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_products_on_workflow_status"
  end

  create_table "project_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_project_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_project_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_project_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_eb5a8d66ff"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_project_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_project_appointments_on_business_type"
    t.index ["company_id"], name: "index_project_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_project_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_project_appointments_on_lifecycle_status"
    t.index ["project_id"], name: "index_project_appointments_on_project_id"
    t.index ["workflow_status"], name: "index_project_appointments_on_workflow_status"
  end

  create_table "project_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_project_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_project_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_project_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_4c26e2a726"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_project_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_project_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_project_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_project_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_project_group_appointments_on_lifecycle_status"
    t.index ["project_group_id"], name: "index_project_group_appointments_on_project_group_id"
    t.index ["workflow_status"], name: "index_project_group_appointments_on_workflow_status"
  end

  create_table "project_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_project_groups_on_branch_id"
    t.index ["business_type"], name: "index_project_groups_on_business_type"
    t.index ["category_id"], name: "index_project_groups_on_category_id"
    t.index ["code"], name: "index_project_groups_on_code", unique: true
    t.index ["company_id"], name: "index_project_groups_on_company_id"
    t.index ["discarded_at"], name: "index_project_groups_on_discarded_at"
    t.index ["email"], name: "index_project_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_project_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_project_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_project_groups_on_workflow_status"
  end

  create_table "projects", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "project_group_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_projects_on_branch_id"
    t.index ["business_type"], name: "index_projects_on_business_type"
    t.index ["category_id"], name: "index_projects_on_category_id"
    t.index ["code"], name: "index_projects_on_code", unique: true
    t.index ["company_id"], name: "index_projects_on_company_id"
    t.index ["discarded_at"], name: "index_projects_on_discarded_at"
    t.index ["email"], name: "index_projects_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_projects_on_lifecycle_status"
    t.index ["project_group_id"], name: "index_projects_on_project_group_id"
    t.index ["property_mapping_id"], name: "index_projects_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_projects_on_workflow_status"
  end

  create_table "property_mappings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_property_mappings_on_business_type"
    t.index ["category_id"], name: "index_property_mappings_on_category_id"
    t.index ["company_id", "category_id"], name: "index_property_mappings_on_company_id_and_category_id"
    t.index ["company_id"], name: "index_property_mappings_on_company_id"
    t.index ["discarded_at"], name: "index_property_mappings_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_property_mappings_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_property_mappings_on_workflow_status"
  end

  create_table "purchase_items", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "purchase_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_purchase_items_on_branch_id"
    t.index ["business_type"], name: "index_purchase_items_on_business_type"
    t.index ["category_id"], name: "index_purchase_items_on_category_id"
    t.index ["code"], name: "index_purchase_items_on_code", unique: true
    t.index ["company_id"], name: "index_purchase_items_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_items_on_discarded_at"
    t.index ["email"], name: "index_purchase_items_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_purchase_items_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_purchase_items_on_property_mapping_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
    t.index ["workflow_status"], name: "index_purchase_items_on_workflow_status"
  end

  create_table "purchases", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_purchases_on_branch_id"
    t.index ["business_type"], name: "index_purchases_on_business_type"
    t.index ["category_id"], name: "index_purchases_on_category_id"
    t.index ["code"], name: "index_purchases_on_code", unique: true
    t.index ["company_id"], name: "index_purchases_on_company_id"
    t.index ["discarded_at"], name: "index_purchases_on_discarded_at"
    t.index ["email"], name: "index_purchases_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_purchases_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_purchases_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_purchases_on_workflow_status"
  end

  create_table "questions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_questions_on_branch_id"
    t.index ["business_type"], name: "index_questions_on_business_type"
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["company_id"], name: "index_questions_on_company_id"
    t.index ["discarded_at"], name: "index_questions_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_questions_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_questions_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_questions_on_workflow_status"
  end

  create_table "reservation_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "reservation_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_reservation_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_reservation_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_reservation_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_fab15553a8"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_reservation_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_reservation_appointments_on_business_type"
    t.index ["company_id"], name: "index_reservation_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_reservation_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_reservation_appointments_on_lifecycle_status"
    t.index ["reservation_id"], name: "index_reservation_appointments_on_reservation_id"
    t.index ["workflow_status"], name: "index_reservation_appointments_on_workflow_status"
  end

  create_table "reservations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_reservations_on_branch_id"
    t.index ["business_type"], name: "index_reservations_on_business_type"
    t.index ["category_id"], name: "index_reservations_on_category_id"
    t.index ["code"], name: "index_reservations_on_code", unique: true
    t.index ["company_id"], name: "index_reservations_on_company_id"
    t.index ["discarded_at"], name: "index_reservations_on_discarded_at"
    t.index ["email"], name: "index_reservations_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_reservations_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_reservations_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_reservations_on_workflow_status"
  end

  create_table "role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "role_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_role_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_role_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_role_appointments_on_business_type"
    t.index ["company_id"], name: "index_role_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_role_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_role_appointments_on_workflow_status"
  end

  create_table "roles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.integer "model_type"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_roles_on_branch_id"
    t.index ["business_type"], name: "index_roles_on_business_type"
    t.index ["company_id"], name: "index_roles_on_company_id"
    t.index ["discarded_at"], name: "index_roles_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_roles_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_roles_on_workflow_status"
  end

  create_table "scheduled_shifts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "shift_template_id"
    t.date "work_date", null: false
    t.datetime "expected_start_at", null: false
    t.datetime "expected_end_at", null: false
    t.integer "status", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_scheduled_shifts_on_branch_id"
    t.index ["company_id"], name: "index_scheduled_shifts_on_company_id"
    t.index ["discarded_at"], name: "index_scheduled_shifts_on_discarded_at"
    t.index ["employee_id", "work_date"], name: "index_scheduled_shifts_on_employee_id_and_work_date", unique: true
    t.index ["employee_id"], name: "index_scheduled_shifts_on_employee_id"
    t.index ["shift_template_id"], name: "index_scheduled_shifts_on_shift_template_id"
  end

  create_table "service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_service_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_service_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_service_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_25f7912f5f"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_service_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_service_appointments_on_business_type"
    t.index ["company_id"], name: "index_service_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_service_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_service_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_service_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_service_appointments_on_workflow_status"
  end

  create_table "service_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_service_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_service_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_service_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_9e69225799"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_service_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_service_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_service_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_service_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_service_group_appointments_on_lifecycle_status"
    t.index ["service_group_id"], name: "index_service_group_appointments_on_service_group_id"
    t.index ["workflow_status"], name: "index_service_group_appointments_on_workflow_status"
  end

  create_table "service_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_service_groups_on_branch_id"
    t.index ["business_type"], name: "index_service_groups_on_business_type"
    t.index ["category_id"], name: "index_service_groups_on_category_id"
    t.index ["code"], name: "index_service_groups_on_code", unique: true
    t.index ["company_id"], name: "index_service_groups_on_company_id"
    t.index ["discarded_at"], name: "index_service_groups_on_discarded_at"
    t.index ["email"], name: "index_service_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_service_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_service_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_service_groups_on_workflow_status"
  end

  create_table "services", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_services_on_branch_id"
    t.index ["business_type"], name: "index_services_on_business_type"
    t.index ["category_id"], name: "index_services_on_category_id"
    t.index ["code"], name: "index_services_on_code", unique: true
    t.index ["company_id"], name: "index_services_on_company_id"
    t.index ["discarded_at"], name: "index_services_on_discarded_at"
    t.index ["email"], name: "index_services_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_services_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_services_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_services_on_workflow_status"
  end

  create_table "sessions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.string "single_access_token"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["single_access_token"], name: "index_sessions_on_single_access_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "setting_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "setting_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_setting_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_setting_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_setting_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_2604430405"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_setting_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_setting_appointments_on_business_type"
    t.index ["company_id"], name: "index_setting_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_setting_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_setting_appointments_on_lifecycle_status"
    t.index ["setting_id"], name: "index_setting_appointments_on_setting_id"
    t.index ["workflow_status"], name: "index_setting_appointments_on_workflow_status"
  end

  create_table "setting_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "setting_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_setting_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_setting_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_setting_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_2769e0ab46"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_setting_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_setting_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_setting_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_setting_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_setting_group_appointments_on_lifecycle_status"
    t.index ["setting_group_id"], name: "index_setting_group_appointments_on_setting_group_id"
    t.index ["workflow_status"], name: "index_setting_group_appointments_on_workflow_status"
  end

  create_table "setting_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_setting_groups_on_branch_id"
    t.index ["business_type"], name: "index_setting_groups_on_business_type"
    t.index ["category_id"], name: "index_setting_groups_on_category_id"
    t.index ["company_id"], name: "index_setting_groups_on_company_id"
    t.index ["discarded_at"], name: "index_setting_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_setting_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_setting_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_setting_groups_on_workflow_status"
  end

  create_table "settings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "setting_group_id", null: false
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.json "content"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_settings_on_branch_id"
    t.index ["business_type"], name: "index_settings_on_business_type"
    t.index ["category_id"], name: "index_settings_on_category_id"
    t.index ["company_id"], name: "index_settings_on_company_id"
    t.index ["discarded_at"], name: "index_settings_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_settings_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_settings_on_property_mapping_id"
    t.index ["setting_group_id"], name: "index_settings_on_setting_group_id"
    t.index ["workflow_status"], name: "index_settings_on_workflow_status"
  end

  create_table "shift_templates", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.string "name", null: false
    t.text "description"
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.integer "grace_period_minutes", null: false
    t.integer "unpaid_break_minutes", null: false
    t.integer "policy_type", null: false
    t.integer "full_day_minutes", null: false
    t.time "core_start_time"
    t.time "core_end_time"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_shift_templates_on_branch_id"
    t.index ["company_id"], name: "index_shift_templates_on_company_id"
    t.index ["discarded_at"], name: "index_shift_templates_on_discarded_at"
  end

  create_table "sign_in_tokens", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "statistics", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.json "data"
    t.datetime "recorded_at"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_statistics_on_owner"
    t.index ["recorded_at"], name: "index_statistics_on_recorded_at"
  end

  create_table "stock_exports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type"
    t.uuid "appoint_to_id"
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "quantity"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.text "property_text_1"
    t.text "property_text_2"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_stock_exports_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_stock_exports_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_stock_exports_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_stock_exports_on_appoint_to"
    t.index ["branch_id"], name: "index_stock_exports_on_branch_id"
    t.index ["business_type"], name: "index_stock_exports_on_business_type"
    t.index ["category_id"], name: "index_stock_exports_on_category_id"
    t.index ["code"], name: "index_stock_exports_on_code", unique: true
    t.index ["company_id"], name: "index_stock_exports_on_company_id"
    t.index ["discarded_at"], name: "index_stock_exports_on_discarded_at"
    t.index ["email"], name: "index_stock_exports_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_stock_exports_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_exports_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_exports_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stock_exports_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_exports_on_workflow_status"
  end

  create_table "stock_imports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type"
    t.uuid "appoint_to_id"
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "quantity"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.text "property_text_1"
    t.text "property_text_2"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_stock_imports_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_stock_imports_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_stock_imports_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_stock_imports_on_appoint_to"
    t.index ["branch_id"], name: "index_stock_imports_on_branch_id"
    t.index ["business_type"], name: "index_stock_imports_on_business_type"
    t.index ["category_id"], name: "index_stock_imports_on_category_id"
    t.index ["code"], name: "index_stock_imports_on_code", unique: true
    t.index ["company_id"], name: "index_stock_imports_on_company_id"
    t.index ["discarded_at"], name: "index_stock_imports_on_discarded_at"
    t.index ["email"], name: "index_stock_imports_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_stock_imports_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_imports_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_imports_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stock_imports_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_imports_on_workflow_status"
  end

  create_table "stock_transactions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type"
    t.uuid "appoint_to_id"
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "quantity", null: false
    t.integer "direction", null: false
    t.integer "transaction_type", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.text "property_text_1"
    t.text "property_text_2"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_stock_transactions_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_stock_transactions_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_stock_transactions_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_stock_transactions_on_appoint_to"
    t.index ["branch_id"], name: "index_stock_transactions_on_branch_id"
    t.index ["business_type"], name: "index_stock_transactions_on_business_type"
    t.index ["category_id"], name: "index_stock_transactions_on_category_id"
    t.index ["code"], name: "index_stock_transactions_on_code", unique: true
    t.index ["company_id"], name: "index_stock_transactions_on_company_id"
    t.index ["direction"], name: "index_stock_transactions_on_direction"
    t.index ["discarded_at"], name: "index_stock_transactions_on_discarded_at"
    t.index ["email"], name: "index_stock_transactions_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_stock_transactions_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_transactions_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_transactions_on_property_mapping_id"
    t.index ["transaction_type"], name: "index_stock_transactions_on_transaction_type"
    t.index ["warehouse_id"], name: "index_stock_transactions_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_transactions_on_workflow_status"
  end

  create_table "stock_transfers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type"
    t.uuid "appoint_to_id"
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "quantity"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.text "property_text_1"
    t.text "property_text_2"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_stock_transfers_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_stock_transfers_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_stock_transfers_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_stock_transfers_on_appoint_to"
    t.index ["branch_id"], name: "index_stock_transfers_on_branch_id"
    t.index ["business_type"], name: "index_stock_transfers_on_business_type"
    t.index ["category_id"], name: "index_stock_transfers_on_category_id"
    t.index ["code"], name: "index_stock_transfers_on_code", unique: true
    t.index ["company_id"], name: "index_stock_transfers_on_company_id"
    t.index ["discarded_at"], name: "index_stock_transfers_on_discarded_at"
    t.index ["email"], name: "index_stock_transfers_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_stock_transfers_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_transfers_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_transfers_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stock_transfers_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_transfers_on_workflow_status"
  end

  create_table "stocks", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "product_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "quantity", null: false
    t.integer "reorder", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.text "property_text_1"
    t.text "property_text_2"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_stocks_on_branch_id"
    t.index ["business_type"], name: "index_stocks_on_business_type"
    t.index ["category_id"], name: "index_stocks_on_category_id"
    t.index ["code"], name: "index_stocks_on_code", unique: true
    t.index ["company_id"], name: "index_stocks_on_company_id"
    t.index ["discarded_at"], name: "index_stocks_on_discarded_at"
    t.index ["email"], name: "index_stocks_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_stocks_on_lifecycle_status"
    t.index ["product_id"], name: "index_stocks_on_product_id"
    t.index ["property_mapping_id"], name: "index_stocks_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stocks_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stocks_on_workflow_status"
  end

  create_table "subscription_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "subscription_plan_id"
    t.uuid "subscription_group_id"
    t.string "name"
    t.string "description"
    t.integer "country", null: false
    t.integer "timezone"
    t.boolean "auto_renew"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_subscription_groups_on_branch_id"
    t.index ["business_type"], name: "index_subscription_groups_on_business_type"
    t.index ["company_id"], name: "index_subscription_groups_on_company_id"
    t.index ["discarded_at"], name: "index_subscription_groups_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_subscription_groups_on_lifecycle_status"
    t.index ["subscription_group_id"], name: "index_subscription_groups_on_subscription_group_id"
    t.index ["subscription_plan_id"], name: "index_subscription_groups_on_subscription_plan_id"
    t.index ["workflow_status"], name: "index_subscription_groups_on_workflow_status"
  end

  create_table "subscription_plan_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "subscription_plan_id"
    t.uuid "subscription_group_id"
    t.string "name"
    t.string "description"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country", null: false
    t.integer "timezone"
    t.boolean "auto_renew"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_subscription_plan_appointments_on_branch_id"
    t.index ["business_type"], name: "index_subscription_plan_appointments_on_business_type"
    t.index ["company_id"], name: "index_subscription_plan_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_subscription_plan_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_subscription_plan_appointments_on_lifecycle_status"
    t.index ["subscription_group_id"], name: "index_subscription_plan_appointments_on_subscription_group_id"
    t.index ["subscription_plan_id"], name: "index_subscription_plan_appointments_on_subscription_plan_id"
    t.index ["workflow_status"], name: "index_subscription_plan_appointments_on_workflow_status"
  end

  create_table "subscription_plans", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.string "name", null: false
    t.string "description"
    t.string "code"
    t.integer "duration_days"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_subscription_plans_on_branch_id"
    t.index ["business_type"], name: "index_subscription_plans_on_business_type"
    t.index ["company_id"], name: "index_subscription_plans_on_company_id"
    t.index ["discarded_at"], name: "index_subscription_plans_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_subscription_plans_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_subscription_plans_on_workflow_status"
  end

  create_table "systems", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "email"
    t.string "name", null: false
    t.string "code", null: false, comment: "System"
    t.integer "balance_cents", null: false
    t.integer "currency"
    t.integer "country"
    t.boolean "active", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_systems_on_business_type"
    t.index ["discarded_at"], name: "index_systems_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_systems_on_lifecycle_status"
    t.index ["name"], name: "index_systems_on_name", unique: true
    t.index ["workflow_status"], name: "index_systems_on_workflow_status"
  end

  create_table "table_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id"
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_table_configs_on_business_type"
    t.index ["category_id"], name: "index_table_configs_on_category_id"
    t.index ["company_id", "resource_name", "category_id"], name: "idx_on_company_id_resource_name_category_id_66b8ad4700"
    t.index ["company_id"], name: "index_table_configs_on_company_id"
    t.index ["discarded_at"], name: "index_table_configs_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_table_configs_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_table_configs_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_table_configs_on_workflow_status"
  end

  create_table "tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "value"
    t.string "description"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_tag_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_tag_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_tag_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_tag_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_tag_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_tag_appointments_on_business_type"
    t.index ["company_id"], name: "index_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_tag_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_tag_appointments_on_workflow_status"
  end

  create_table "tags", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "key"
    t.string "value"
    t.string "description"
    t.string "code"
    t.string "permission_resource_name"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tags_on_business_type"
    t.index ["company_id"], name: "index_tags_on_company_id"
    t.index ["discarded_at"], name: "index_tags_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_tags_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_tags_on_workflow_status"
  end

  create_table "task_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "task_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_task_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_task_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_task_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_task_appointments_on_appoint_to"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_task_appointments_on_appoint_to_type_and_appoint_to_id"
    t.index ["business_type"], name: "index_task_appointments_on_business_type"
    t.index ["company_id"], name: "index_task_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_task_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_task_appointments_on_lifecycle_status"
    t.index ["task_id"], name: "index_task_appointments_on_task_id"
    t.index ["workflow_status"], name: "index_task_appointments_on_workflow_status"
  end

  create_table "task_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "task_group_id", null: false
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type"
    t.uuid "appoint_for_id"
    t.string "appoint_by_type"
    t.uuid "appoint_by_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_task_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_task_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_task_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "idx_on_appoint_to_type_appoint_to_id_bd79761d5f"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_task_group_appointments_on_appoint_to"
    t.index ["business_type"], name: "index_task_group_appointments_on_business_type"
    t.index ["company_id"], name: "index_task_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_task_group_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_task_group_appointments_on_lifecycle_status"
    t.index ["task_group_id"], name: "index_task_group_appointments_on_task_group_id"
    t.index ["workflow_status"], name: "index_task_group_appointments_on_workflow_status"
  end

  create_table "task_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_task_groups_on_branch_id"
    t.index ["business_type"], name: "index_task_groups_on_business_type"
    t.index ["category_id"], name: "index_task_groups_on_category_id"
    t.index ["code"], name: "index_task_groups_on_code", unique: true
    t.index ["company_id"], name: "index_task_groups_on_company_id"
    t.index ["discarded_at"], name: "index_task_groups_on_discarded_at"
    t.index ["email"], name: "index_task_groups_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_task_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_task_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_task_groups_on_workflow_status"
  end

  create_table "tasks", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "task_group_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_tasks_on_branch_id"
    t.index ["business_type"], name: "index_tasks_on_business_type"
    t.index ["category_id"], name: "index_tasks_on_category_id"
    t.index ["code"], name: "index_tasks_on_code", unique: true
    t.index ["company_id"], name: "index_tasks_on_company_id"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["email"], name: "index_tasks_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_tasks_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_tasks_on_property_mapping_id"
    t.index ["task_group_id"], name: "index_tasks_on_task_group_id"
    t.index ["workflow_status"], name: "index_tasks_on_workflow_status"
  end

  create_table "transactions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "invoice_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.uuid "payment_method_id"
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "payment_status", default: 0, null: false
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_transactions_on_branch_id"
    t.index ["business_type"], name: "index_transactions_on_business_type"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["code"], name: "index_transactions_on_code", unique: true
    t.index ["company_id"], name: "index_transactions_on_company_id"
    t.index ["discarded_at"], name: "index_transactions_on_discarded_at"
    t.index ["email"], name: "index_transactions_on_email", unique: true
    t.index ["invoice_id"], name: "index_transactions_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_transactions_on_lifecycle_status"
    t.index ["payment_method_id"], name: "index_transactions_on_payment_method_id"
    t.index ["property_mapping_id"], name: "index_transactions_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_transactions_on_workflow_status"
  end

  create_table "users", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", null: false
    t.string "provider"
    t.string "uid"
    t.uuid "parent_user_id"
    t.integer "system_role"
    t.string "username"
    t.string "name"
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.string "phone_number"
    t.integer "country"
    t.string "single_access_token"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_users_on_business_type"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_users_on_lifecycle_status"
    t.index ["parent_user_id"], name: "index_users_on_parent_user_id"
    t.index ["single_access_token"], name: "index_users_on_single_access_token", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["workflow_status"], name: "index_users_on_workflow_status"
  end

  create_table "versions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.string "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "warehouses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
    t.string "property_string_6"
    t.string "property_string_7"
    t.string "property_string_8"
    t.string "property_string_9"
    t.string "property_string_10"
    t.text "property_text_1"
    t.text "property_text_2"
    t.text "property_text_3"
    t.text "property_text_4"
    t.text "property_text_5"
    t.integer "property_integer_1"
    t.integer "property_integer_2"
    t.integer "property_integer_3"
    t.integer "property_integer_4"
    t.integer "property_integer_5"
    t.integer "property_integer_6"
    t.integer "property_integer_7"
    t.integer "property_integer_8"
    t.integer "property_integer_9"
    t.integer "property_integer_10"
    t.integer "property_integer_11"
    t.integer "property_integer_12"
    t.integer "property_integer_13"
    t.integer "property_integer_14"
    t.integer "property_integer_15"
    t.integer "property_integer_16"
    t.integer "property_integer_17"
    t.integer "property_integer_18"
    t.integer "property_integer_19"
    t.integer "property_integer_20"
    t.decimal "property_decimal_1", precision: 15, scale: 4
    t.decimal "property_decimal_2", precision: 15, scale: 4
    t.decimal "property_decimal_3", precision: 15, scale: 4
    t.decimal "property_decimal_4", precision: 15, scale: 4
    t.decimal "property_decimal_5", precision: 15, scale: 4
    t.decimal "property_decimal_6", precision: 15, scale: 4
    t.decimal "property_decimal_7", precision: 15, scale: 4
    t.decimal "property_decimal_8", precision: 15, scale: 4
    t.decimal "property_decimal_9", precision: 15, scale: 4
    t.decimal "property_decimal_10", precision: 15, scale: 4
    t.boolean "property_boolean_1"
    t.boolean "property_boolean_2"
    t.boolean "property_boolean_3"
    t.boolean "property_boolean_4"
    t.boolean "property_boolean_5"
    t.boolean "property_boolean_6"
    t.boolean "property_boolean_7"
    t.boolean "property_boolean_8"
    t.boolean "property_boolean_9"
    t.boolean "property_boolean_10"
    t.datetime "property_datetime_1"
    t.datetime "property_datetime_2"
    t.datetime "property_datetime_3"
    t.datetime "property_datetime_4"
    t.datetime "property_datetime_5"
    t.datetime "property_datetime_6"
    t.datetime "property_datetime_7"
    t.datetime "property_datetime_8"
    t.datetime "property_datetime_9"
    t.datetime "property_datetime_10"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_warehouses_on_branch_id"
    t.index ["business_type"], name: "index_warehouses_on_business_type"
    t.index ["category_id"], name: "index_warehouses_on_category_id"
    t.index ["code"], name: "index_warehouses_on_code", unique: true
    t.index ["company_id"], name: "index_warehouses_on_company_id"
    t.index ["discarded_at"], name: "index_warehouses_on_discarded_at"
    t.index ["email"], name: "index_warehouses_on_email", unique: true
    t.index ["lifecycle_status"], name: "index_warehouses_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_warehouses_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_warehouses_on_workflow_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "address_appointments", "addresses"
  add_foreign_key "answers", "categories"
  add_foreign_key "answers", "companies"
  add_foreign_key "answers", "property_mappings"
  add_foreign_key "answers", "questions"
  add_foreign_key "article_appointments", "articles"
  add_foreign_key "article_appointments", "companies"
  add_foreign_key "article_group_appointments", "article_groups"
  add_foreign_key "article_group_appointments", "companies"
  add_foreign_key "article_groups", "branches"
  add_foreign_key "article_groups", "categories"
  add_foreign_key "article_groups", "companies"
  add_foreign_key "article_groups", "property_mappings"
  add_foreign_key "articles", "article_groups"
  add_foreign_key "articles", "branches"
  add_foreign_key "articles", "categories"
  add_foreign_key "articles", "companies"
  add_foreign_key "articles", "property_mappings"
  add_foreign_key "attendance_days", "branches"
  add_foreign_key "attendance_days", "companies"
  add_foreign_key "attendance_days", "employees"
  add_foreign_key "attendance_logs", "branches"
  add_foreign_key "attendance_logs", "companies"
  add_foreign_key "attendance_logs", "employees"
  add_foreign_key "attendance_months", "branches"
  add_foreign_key "attendance_months", "companies"
  add_foreign_key "attendance_months", "employees"
  add_foreign_key "attendance_policies", "branches"
  add_foreign_key "attendance_policies", "companies"
  add_foreign_key "billing_contracts", "companies"
  add_foreign_key "billing_invoices", "billing_contracts"
  add_foreign_key "billing_invoices", "companies"
  add_foreign_key "billing_transactions", "billing_invoices"
  add_foreign_key "billing_transactions", "billing_payment_methods"
  add_foreign_key "billing_transactions", "companies"
  add_foreign_key "billing_wallets", "companies"
  add_foreign_key "branches", "branches", column: "parent_branch_id"
  add_foreign_key "branches", "categories"
  add_foreign_key "branches", "companies"
  add_foreign_key "branches", "property_mappings"
  add_foreign_key "brands", "categories"
  add_foreign_key "brands", "companies"
  add_foreign_key "brands", "property_mappings"
  add_foreign_key "cart_appointments", "carts"
  add_foreign_key "cart_appointments", "companies"
  add_foreign_key "cart_groups", "branches"
  add_foreign_key "cart_groups", "categories"
  add_foreign_key "cart_groups", "companies"
  add_foreign_key "cart_groups", "property_mappings"
  add_foreign_key "carts", "branches"
  add_foreign_key "carts", "cart_groups"
  add_foreign_key "carts", "categories"
  add_foreign_key "carts", "companies"
  add_foreign_key "carts", "property_mappings"
  add_foreign_key "categories", "companies"
  add_foreign_key "companies", "users"
  add_foreign_key "contract_features", "billing_contracts"
  add_foreign_key "contract_features", "billing_resources"
  add_foreign_key "contract_metrics", "billing_contracts"
  add_foreign_key "contract_metrics", "billing_resources"
  add_foreign_key "customer_appointments", "companies"
  add_foreign_key "customer_appointments", "customers"
  add_foreign_key "customer_group_appointments", "companies"
  add_foreign_key "customer_group_appointments", "customer_groups"
  add_foreign_key "customer_groups", "branches"
  add_foreign_key "customer_groups", "categories"
  add_foreign_key "customer_groups", "companies"
  add_foreign_key "customer_groups", "property_mappings"
  add_foreign_key "customers", "branches"
  add_foreign_key "customers", "categories"
  add_foreign_key "customers", "companies"
  add_foreign_key "customers", "property_mappings"
  add_foreign_key "customers", "users"
  add_foreign_key "daily_feature_logs", "companies"
  add_foreign_key "daily_feature_logs", "contract_features"
  add_foreign_key "daily_metric_logs", "billing_resources"
  add_foreign_key "daily_metric_logs", "companies"
  add_foreign_key "department_appointments", "companies"
  add_foreign_key "department_appointments", "departments"
  add_foreign_key "departments", "categories"
  add_foreign_key "departments", "companies"
  add_foreign_key "departments", "property_mappings"
  add_foreign_key "document_appointments", "companies"
  add_foreign_key "document_appointments", "documents"
  add_foreign_key "document_group_appointments", "companies"
  add_foreign_key "document_group_appointments", "document_groups"
  add_foreign_key "document_groups", "branches"
  add_foreign_key "document_groups", "categories"
  add_foreign_key "document_groups", "companies"
  add_foreign_key "document_groups", "property_mappings"
  add_foreign_key "documents", "branches"
  add_foreign_key "documents", "categories"
  add_foreign_key "documents", "companies"
  add_foreign_key "documents", "document_groups"
  add_foreign_key "documents", "property_mappings"
  add_foreign_key "employee_appointments", "companies"
  add_foreign_key "employee_appointments", "employees"
  add_foreign_key "employee_group_appointments", "companies"
  add_foreign_key "employee_group_appointments", "employee_groups"
  add_foreign_key "employee_groups", "branches"
  add_foreign_key "employee_groups", "categories"
  add_foreign_key "employee_groups", "companies"
  add_foreign_key "employee_groups", "property_mappings"
  add_foreign_key "employees", "branches"
  add_foreign_key "employees", "categories"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "property_mappings"
  add_foreign_key "employees", "users"
  add_foreign_key "event_appointments", "companies"
  add_foreign_key "event_appointments", "events"
  add_foreign_key "event_group_appointments", "companies"
  add_foreign_key "event_group_appointments", "event_groups"
  add_foreign_key "event_groups", "branches"
  add_foreign_key "event_groups", "categories"
  add_foreign_key "event_groups", "companies"
  add_foreign_key "event_groups", "property_mappings"
  add_foreign_key "events", "branches"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "companies"
  add_foreign_key "events", "event_groups"
  add_foreign_key "events", "property_mappings"
  add_foreign_key "exam_appointments", "companies"
  add_foreign_key "exam_appointments", "exams"
  add_foreign_key "exam_groups", "branches"
  add_foreign_key "exam_groups", "categories"
  add_foreign_key "exam_groups", "companies"
  add_foreign_key "exam_groups", "property_mappings"
  add_foreign_key "exams", "branches"
  add_foreign_key "exams", "categories"
  add_foreign_key "exams", "companies"
  add_foreign_key "exams", "exam_groups"
  add_foreign_key "exams", "property_mappings"
  add_foreign_key "facilities", "branches"
  add_foreign_key "facilities", "categories"
  add_foreign_key "facilities", "companies"
  add_foreign_key "facilities", "property_mappings"
  add_foreign_key "facility_appointments", "companies"
  add_foreign_key "facility_appointments", "facilities"
  add_foreign_key "facility_group_appointments", "companies"
  add_foreign_key "facility_group_appointments", "facility_groups"
  add_foreign_key "facility_groups", "branches"
  add_foreign_key "facility_groups", "categories"
  add_foreign_key "facility_groups", "companies"
  add_foreign_key "facility_groups", "property_mappings"
  add_foreign_key "invoices", "branches"
  add_foreign_key "invoices", "categories"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "orders"
  add_foreign_key "invoices", "property_mappings"
  add_foreign_key "membership_appointments", "companies"
  add_foreign_key "membership_appointments", "memberships"
  add_foreign_key "memberships", "branches"
  add_foreign_key "memberships", "categories"
  add_foreign_key "memberships", "companies"
  add_foreign_key "memberships", "property_mappings"
  add_foreign_key "notification_appointments", "companies"
  add_foreign_key "notification_appointments", "notifications"
  add_foreign_key "notification_group_appointments", "companies"
  add_foreign_key "notification_group_appointments", "notification_groups"
  add_foreign_key "notification_groups", "branches"
  add_foreign_key "notification_groups", "categories"
  add_foreign_key "notification_groups", "companies"
  add_foreign_key "notification_groups", "property_mappings"
  add_foreign_key "notifications", "branches"
  add_foreign_key "notifications", "categories"
  add_foreign_key "notifications", "companies"
  add_foreign_key "notifications", "notification_groups"
  add_foreign_key "notifications", "property_mappings"
  add_foreign_key "order_appointments", "companies"
  add_foreign_key "order_appointments", "orders"
  add_foreign_key "order_group_appointments", "companies"
  add_foreign_key "order_group_appointments", "order_groups"
  add_foreign_key "order_groups", "branches"
  add_foreign_key "order_groups", "categories"
  add_foreign_key "order_groups", "companies"
  add_foreign_key "order_groups", "customers"
  add_foreign_key "order_groups", "property_mappings"
  add_foreign_key "orders", "branches"
  add_foreign_key "orders", "categories"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "property_mappings"
  add_foreign_key "pages", "branches"
  add_foreign_key "pages", "companies"
  add_foreign_key "payment_method_appointments", "branches"
  add_foreign_key "payment_method_appointments", "companies"
  add_foreign_key "payment_method_appointments", "payment_methods"
  add_foreign_key "policies", "branches"
  add_foreign_key "policies", "companies"
  add_foreign_key "policy_appointments", "companies"
  add_foreign_key "policy_appointments", "policies"
  add_foreign_key "product_appointments", "companies"
  add_foreign_key "product_appointments", "products"
  add_foreign_key "product_group_appointments", "companies"
  add_foreign_key "product_group_appointments", "product_groups"
  add_foreign_key "product_groups", "branches"
  add_foreign_key "product_groups", "categories"
  add_foreign_key "product_groups", "companies"
  add_foreign_key "product_groups", "property_mappings"
  add_foreign_key "products", "branches"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "property_mappings"
  add_foreign_key "project_appointments", "companies"
  add_foreign_key "project_appointments", "projects"
  add_foreign_key "project_group_appointments", "companies"
  add_foreign_key "project_group_appointments", "project_groups"
  add_foreign_key "project_groups", "branches"
  add_foreign_key "project_groups", "categories"
  add_foreign_key "project_groups", "companies"
  add_foreign_key "project_groups", "property_mappings"
  add_foreign_key "projects", "branches"
  add_foreign_key "projects", "categories"
  add_foreign_key "projects", "companies"
  add_foreign_key "projects", "project_groups"
  add_foreign_key "projects", "property_mappings"
  add_foreign_key "property_mappings", "categories"
  add_foreign_key "property_mappings", "companies"
  add_foreign_key "purchase_items", "branches"
  add_foreign_key "purchase_items", "categories"
  add_foreign_key "purchase_items", "companies"
  add_foreign_key "purchase_items", "property_mappings"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "branches"
  add_foreign_key "purchases", "categories"
  add_foreign_key "purchases", "companies"
  add_foreign_key "purchases", "property_mappings"
  add_foreign_key "questions", "branches"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "companies"
  add_foreign_key "questions", "property_mappings"
  add_foreign_key "reservation_appointments", "companies"
  add_foreign_key "reservation_appointments", "reservations"
  add_foreign_key "reservations", "branches"
  add_foreign_key "reservations", "categories"
  add_foreign_key "reservations", "companies"
  add_foreign_key "reservations", "property_mappings"
  add_foreign_key "role_appointments", "companies"
  add_foreign_key "role_appointments", "roles"
  add_foreign_key "roles", "branches"
  add_foreign_key "roles", "companies"
  add_foreign_key "scheduled_shifts", "branches"
  add_foreign_key "scheduled_shifts", "companies"
  add_foreign_key "scheduled_shifts", "employees"
  add_foreign_key "scheduled_shifts", "shift_templates"
  add_foreign_key "service_appointments", "companies"
  add_foreign_key "service_appointments", "services"
  add_foreign_key "service_group_appointments", "companies"
  add_foreign_key "service_group_appointments", "service_groups"
  add_foreign_key "service_groups", "branches"
  add_foreign_key "service_groups", "categories"
  add_foreign_key "service_groups", "companies"
  add_foreign_key "service_groups", "property_mappings"
  add_foreign_key "services", "branches"
  add_foreign_key "services", "categories"
  add_foreign_key "services", "companies"
  add_foreign_key "services", "property_mappings"
  add_foreign_key "sessions", "users"
  add_foreign_key "setting_appointments", "companies"
  add_foreign_key "setting_appointments", "settings"
  add_foreign_key "setting_group_appointments", "companies"
  add_foreign_key "setting_group_appointments", "setting_groups"
  add_foreign_key "setting_groups", "branches"
  add_foreign_key "setting_groups", "categories"
  add_foreign_key "setting_groups", "companies"
  add_foreign_key "setting_groups", "property_mappings"
  add_foreign_key "settings", "branches"
  add_foreign_key "settings", "categories"
  add_foreign_key "settings", "companies"
  add_foreign_key "settings", "property_mappings"
  add_foreign_key "settings", "setting_groups"
  add_foreign_key "shift_templates", "branches"
  add_foreign_key "shift_templates", "companies"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "stock_exports", "branches"
  add_foreign_key "stock_exports", "categories"
  add_foreign_key "stock_exports", "companies"
  add_foreign_key "stock_exports", "products"
  add_foreign_key "stock_exports", "property_mappings"
  add_foreign_key "stock_exports", "warehouses"
  add_foreign_key "stock_imports", "branches"
  add_foreign_key "stock_imports", "categories"
  add_foreign_key "stock_imports", "companies"
  add_foreign_key "stock_imports", "products"
  add_foreign_key "stock_imports", "property_mappings"
  add_foreign_key "stock_imports", "warehouses"
  add_foreign_key "stock_transactions", "branches"
  add_foreign_key "stock_transactions", "categories"
  add_foreign_key "stock_transactions", "companies"
  add_foreign_key "stock_transactions", "products"
  add_foreign_key "stock_transactions", "property_mappings"
  add_foreign_key "stock_transactions", "warehouses"
  add_foreign_key "stock_transfers", "branches"
  add_foreign_key "stock_transfers", "categories"
  add_foreign_key "stock_transfers", "companies"
  add_foreign_key "stock_transfers", "products"
  add_foreign_key "stock_transfers", "property_mappings"
  add_foreign_key "stock_transfers", "warehouses"
  add_foreign_key "stocks", "branches"
  add_foreign_key "stocks", "categories"
  add_foreign_key "stocks", "companies"
  add_foreign_key "stocks", "products"
  add_foreign_key "stocks", "property_mappings"
  add_foreign_key "stocks", "warehouses"
  add_foreign_key "subscription_groups", "branches"
  add_foreign_key "subscription_groups", "companies"
  add_foreign_key "subscription_groups", "subscription_groups"
  add_foreign_key "subscription_groups", "subscription_plans"
  add_foreign_key "subscription_plan_appointments", "branches"
  add_foreign_key "subscription_plan_appointments", "companies"
  add_foreign_key "subscription_plan_appointments", "subscription_groups"
  add_foreign_key "subscription_plan_appointments", "subscription_plans"
  add_foreign_key "subscription_plans", "branches"
  add_foreign_key "subscription_plans", "companies"
  add_foreign_key "table_configs", "categories"
  add_foreign_key "table_configs", "companies"
  add_foreign_key "table_configs", "property_mappings"
  add_foreign_key "tag_appointments", "companies"
  add_foreign_key "tag_appointments", "tags"
  add_foreign_key "tags", "companies"
  add_foreign_key "task_appointments", "companies"
  add_foreign_key "task_appointments", "tasks"
  add_foreign_key "task_group_appointments", "companies"
  add_foreign_key "task_group_appointments", "task_groups"
  add_foreign_key "task_groups", "branches"
  add_foreign_key "task_groups", "categories"
  add_foreign_key "task_groups", "companies"
  add_foreign_key "task_groups", "property_mappings"
  add_foreign_key "tasks", "branches"
  add_foreign_key "tasks", "categories"
  add_foreign_key "tasks", "companies"
  add_foreign_key "tasks", "property_mappings"
  add_foreign_key "tasks", "task_groups"
  add_foreign_key "transactions", "branches"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "companies"
  add_foreign_key "transactions", "invoices"
  add_foreign_key "transactions", "payment_methods"
  add_foreign_key "transactions", "property_mappings"
  add_foreign_key "users", "users", column: "parent_user_id"
  add_foreign_key "warehouses", "branches"
  add_foreign_key "warehouses", "categories"
  add_foreign_key "warehouses", "companies"
  add_foreign_key "warehouses", "property_mappings"
end
