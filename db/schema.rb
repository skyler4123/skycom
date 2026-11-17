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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_000095) do
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

  create_table "address_branch_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "branch_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_branch_appointments_on_address_id"
    t.index ["branch_id"], name: "index_address_branch_appointments_on_branch_id"
    t.index ["business_type"], name: "index_address_branch_appointments_on_business_type"
    t.index ["company_id", "address_id", "branch_id"], name: "idx_address_branch_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_branch_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_address_branch_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_branch_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_branch_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_branch_appointments_on_workflow_status"
  end

  create_table "address_company_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "address_id", null: false
    t.uuid "company_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id", "company_id"], name: "idx_address_company_appointments_uniq", unique: true
    t.index ["address_id"], name: "index_address_company_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_company_appointments_on_business_type"
    t.index ["company_id"], name: "index_address_company_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_address_company_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_company_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_company_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_company_appointments_on_workflow_status"
  end

  create_table "address_customer_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "customer_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_customer_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_customer_appointments_on_business_type"
    t.index ["company_id", "address_id", "customer_id"], name: "idx_address_customer_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_customer_appointments_on_company_id"
    t.index ["customer_id"], name: "index_address_customer_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_address_customer_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_customer_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_customer_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_customer_appointments_on_workflow_status"
  end

  create_table "address_customer_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "customer_group_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_customer_group_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_customer_group_appointments_on_business_type"
    t.index ["company_id", "address_id", "customer_group_id"], name: "idx_address_customer_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_customer_group_appointments_on_company_id"
    t.index ["customer_group_id"], name: "index_address_customer_group_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_address_customer_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_customer_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_customer_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_customer_group_appointments_on_workflow_status"
  end

  create_table "address_department_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "department_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_department_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_department_appointments_on_business_type"
    t.index ["company_id", "address_id", "department_id"], name: "idx_address_department_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_department_appointments_on_company_id"
    t.index ["department_id"], name: "index_address_department_appointments_on_department_id"
    t.index ["discarded_at"], name: "index_address_department_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_department_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_department_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_department_appointments_on_workflow_status"
  end

  create_table "address_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "employee_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_employee_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_employee_appointments_on_business_type"
    t.index ["company_id", "address_id", "employee_id"], name: "idx_address_employee_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_employee_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_address_employee_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_address_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_address_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_employee_appointments_on_workflow_status"
  end

  create_table "address_employee_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "employee_group_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_employee_group_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_employee_group_appointments_on_business_type"
    t.index ["company_id", "address_id", "employee_group_id"], name: "idx_address_employee_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_employee_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_address_employee_group_appointments_on_discarded_at"
    t.index ["employee_group_id"], name: "index_address_employee_group_appointments_on_employee_group_id"
    t.index ["external_id"], name: "index_address_employee_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_employee_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_address_employee_group_appointments_on_workflow_status"
  end

  create_table "address_user_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "address_id", null: false
    t.uuid "user_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_address_user_appointments_on_address_id"
    t.index ["business_type"], name: "index_address_user_appointments_on_business_type"
    t.index ["company_id", "address_id", "user_id"], name: "idx_address_user_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_address_user_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_address_user_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_address_user_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_address_user_appointments_on_lifecycle_status"
    t.index ["user_id"], name: "index_address_user_appointments_on_user_id"
    t.index ["workflow_status"], name: "index_address_user_appointments_on_workflow_status"
  end

  create_table "addresses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "line_1", null: false
    t.string "line_2"
    t.string "city", null: false
    t.string "state_or_province"
    t.string "postal_code"
    t.integer "country"
    t.string "fingerprint", null: false
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_addresses_on_external_id"
    t.index ["fingerprint"], name: "index_addresses_on_fingerprint", unique: true
  end

  create_table "analytics", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status", default: 1, null: false
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_analytics_on_company_id_and_name", unique: true
    t.index ["company_id", "workflow_status"], name: "index_analytics_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_analytics_on_company_id"
    t.index ["discarded_at"], name: "index_analytics_on_discarded_at"
  end

  create_table "api_keys", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "created_by_employee_id"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.jsonb "scopes", default: []
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "revoked_at"], name: "index_api_keys_on_company_id_and_revoked_at"
    t.index ["company_id"], name: "index_api_keys_on_company_id"
    t.index ["created_by_employee_id"], name: "index_api_keys_on_created_by_employee_id"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "applicant_interviews", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "applicant_id", null: false
    t.uuid "employee_id"
    t.datetime "scheduled_at", null: false
    t.datetime "completed_at"
    t.integer "outcome", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applicant_id", "scheduled_at"], name: "index_applicant_interviews_on_applicant_id_and_scheduled_at"
    t.index ["applicant_id"], name: "index_applicant_interviews_on_applicant_id"
    t.index ["business_type"], name: "index_applicant_interviews_on_business_type"
    t.index ["company_id"], name: "index_applicant_interviews_on_company_id"
    t.index ["discarded_at"], name: "index_applicant_interviews_on_discarded_at"
    t.index ["employee_id"], name: "index_applicant_interviews_on_employee_id"
    t.index ["lifecycle_status"], name: "index_applicant_interviews_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_applicant_interviews_on_workflow_status"
  end

  create_table "applicants", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "job_opening_id", null: false
    t.uuid "resume_stored_file_id"
    t.uuid "workflow_step_id"
    t.string "name", null: false
    t.string "email"
    t.string "phone_number"
    t.string "source"
    t.integer "stage", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_applicants_on_business_type"
    t.index ["company_id", "stage"], name: "index_applicants_on_company_id_and_stage"
    t.index ["company_id"], name: "index_applicants_on_company_id"
    t.index ["discarded_at"], name: "index_applicants_on_discarded_at"
    t.index ["job_opening_id", "stage"], name: "index_applicants_on_job_opening_id_and_stage"
    t.index ["job_opening_id"], name: "index_applicants_on_job_opening_id"
    t.index ["lifecycle_status"], name: "index_applicants_on_lifecycle_status"
    t.index ["resume_stored_file_id"], name: "index_applicants_on_resume_stored_file_id"
    t.index ["workflow_status"], name: "index_applicants_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_applicants_on_workflow_step_id"
  end

  create_table "attendance_balances", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.integer "year", null: false
    t.decimal "entitled_days", precision: 5, scale: 1, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_attendance_balances_on_company_id"
    t.index ["employee_id", "year"], name: "index_attendance_balances_on_employee_id_and_year", unique: true
    t.index ["employee_id"], name: "index_attendance_balances_on_employee_id"
  end

  create_table "attendance_config_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "attendance_config_id"
    t.uuid "branch_id"
    t.uuid "employee_id"
    t.integer "action", null: false
    t.string "employee_name"
    t.string "branch_name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "allowed_radius_meters"
    t.string "allowed_wifi_ssid"
    t.boolean "require_photo"
    t.integer "resolution_strategy"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_config_id"], name: "index_attendance_config_logs_on_attendance_config_id"
    t.index ["branch_id"], name: "index_attendance_config_logs_on_branch_id"
    t.index ["company_id", "attendance_config_id", "created_at"], name: "idx_attendance_config_logs_on_config_time"
    t.index ["company_id", "created_at"], name: "idx_attendance_config_logs_on_company_time"
    t.index ["company_id"], name: "index_attendance_config_logs_on_company_id"
    t.index ["employee_id"], name: "index_attendance_config_logs_on_employee_id"
    t.index ["external_id"], name: "index_attendance_config_logs_on_external_id"
  end

  create_table "attendance_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.integer "allowed_radius_meters", null: false
    t.string "allowed_wifi_ssid"
    t.boolean "require_photo", null: false
    t.integer "resolution_strategy", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_configs_on_branch_id", unique: true
    t.index ["company_id"], name: "index_attendance_configs_on_company_id"
    t.index ["discarded_at"], name: "index_attendance_configs_on_discarded_at"
    t.index ["external_id"], name: "index_attendance_configs_on_external_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_attendance_days_on_external_id"
  end

  create_table "attendance_leaves", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.uuid "decided_by_id"
    t.integer "leave_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "days", precision: 5, scale: 1, default: "0.0", null: false
    t.text "reason"
    t.text "decision_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_leaves_on_branch_id"
    t.index ["company_id"], name: "index_attendance_leaves_on_company_id"
    t.index ["decided_by_id"], name: "index_attendance_leaves_on_decided_by_id"
    t.index ["employee_id", "start_date"], name: "index_attendance_leaves_on_employee_id_and_start_date"
    t.index ["employee_id"], name: "index_attendance_leaves_on_employee_id"
    t.index ["start_date"], name: "index_attendance_leaves_on_start_date"
    t.index ["status"], name: "index_attendance_leaves_on_status"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_attendance_logs_on_external_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_attendance_months_on_external_id"
  end

  create_table "attendance_requests", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.date "attendance_date", null: false
    t.datetime "check_in", null: false
    t.datetime "check_out"
    t.text "reason", null: false
    t.integer "status", default: 0, null: false
    t.uuid "decided_by_id"
    t.datetime "decided_at"
    t.text "decision_note"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_attendance_requests_on_branch_id"
    t.index ["company_id", "employee_id", "attendance_date"], name: "idx_attendance_requests_on_company_employee_date", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_attendance_requests_on_company_id"
    t.index ["decided_by_id"], name: "index_attendance_requests_on_decided_by_id"
    t.index ["discarded_at"], name: "index_attendance_requests_on_discarded_at"
    t.index ["employee_id"], name: "index_attendance_requests_on_employee_id"
    t.index ["external_id"], name: "index_attendance_requests_on_external_id"
    t.index ["status"], name: "index_attendance_requests_on_status"
  end

  create_table "bill_of_materials", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.string "name"
    t.string "version", default: "1", null: false
    t.integer "output_quantity", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_bill_of_materials_on_business_type"
    t.index ["company_id", "product_id", "version"], name: "idx_bom_version_unique", unique: true
    t.index ["company_id"], name: "index_bill_of_materials_on_company_id"
    t.index ["discarded_at"], name: "index_bill_of_materials_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_bill_of_materials_on_lifecycle_status"
    t.index ["product_id"], name: "index_bill_of_materials_on_product_id"
    t.index ["workflow_status"], name: "index_bill_of_materials_on_workflow_status"
  end

  create_table "billing_schedules", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "subscription_group_id", null: false
    t.integer "interval", default: 1, null: false
    t.integer "interval_count", default: 1, null: false
    t.date "next_run_on", null: false
    t.date "last_run_on"
    t.integer "status", default: 0, null: false
    t.datetime "canceled_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_billing_schedules_on_business_type"
    t.index ["company_id", "next_run_on"], name: "index_billing_schedules_on_company_id_and_next_run_on"
    t.index ["company_id"], name: "index_billing_schedules_on_company_id"
    t.index ["discarded_at"], name: "index_billing_schedules_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_billing_schedules_on_lifecycle_status"
    t.index ["subscription_group_id"], name: "index_billing_schedules_on_subscription_group_id", unique: true
    t.index ["workflow_status"], name: "index_billing_schedules_on_workflow_status"
  end

  create_table "bom_lines", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "bill_of_material_id", null: false
    t.uuid "component_product_id", null: false
    t.decimal "quantity", precision: 15, scale: 4, default: "1.0", null: false
    t.integer "scrap_bp", default: 0, null: false
    t.integer "position", default: 1, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_of_material_id", "position"], name: "index_bom_lines_on_bill_of_material_id_and_position", unique: true
    t.index ["bill_of_material_id"], name: "index_bom_lines_on_bill_of_material_id"
    t.index ["business_type"], name: "index_bom_lines_on_business_type"
    t.index ["company_id"], name: "index_bom_lines_on_company_id"
    t.index ["component_product_id"], name: "index_bom_lines_on_component_product_id"
    t.index ["discarded_at"], name: "index_bom_lines_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_bom_lines_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_bom_lines_on_workflow_status"
  end

  create_table "branch_event_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "event_id", null: false
    t.string "role"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_event_appointments_on_branch_id"
    t.index ["business_type"], name: "index_branch_event_appointments_on_business_type"
    t.index ["company_id", "branch_id", "event_id"], name: "idx_branch_event_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_branch_event_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_branch_event_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_branch_event_appointments_on_event_id"
    t.index ["external_id"], name: "index_branch_event_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_branch_event_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_branch_event_appointments_on_workflow_status"
  end

  create_table "branch_operation_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "operation_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_operation_appointments_on_branch_id"
    t.index ["company_id", "branch_id", "operation_id"], name: "idx_branch_operation_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_branch_operation_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_branch_operation_appointments_on_discarded_at"
    t.index ["operation_id"], name: "index_branch_operation_appointments_on_operation_id"
  end

  create_table "branch_payment_method_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "payment_method_id", null: false
    t.string "merchant_number"
    t.string "merchant_name"
    t.string "merchant_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_payment_method_appointments_on_branch_id"
    t.index ["business_type"], name: "index_branch_payment_method_appointments_on_business_type"
    t.index ["company_id", "branch_id", "payment_method_id"], name: "idx_branch_payment_method_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_branch_payment_method_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_branch_payment_method_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_branch_payment_method_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_branch_payment_method_appointments_on_lifecycle_status"
    t.index ["payment_method_id"], name: "index_branch_payment_method_appointments_on_payment_method_id"
    t.index ["workflow_status"], name: "index_branch_payment_method_appointments_on_workflow_status"
  end

  create_table "branch_subscription_plan_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "subscription_plan_id", null: false
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.boolean "auto_renew"
    t.string "name"
    t.string "description"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_subscription_plan_appointments_on_branch_id"
    t.index ["business_type"], name: "index_branch_subscription_plan_appointments_on_business_type"
    t.index ["company_id", "branch_id", "subscription_plan_id"], name: "idx_branch_subscription_plan_appointments_triple"
    t.index ["company_id"], name: "index_branch_subscription_plan_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_branch_subscription_plan_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_branch_subscription_plan_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "idx_on_lifecycle_status_6239fe5d2e"
    t.index ["subscription_plan_id"], name: "idx_on_subscription_plan_id_cac211d7dd"
    t.index ["workflow_status"], name: "index_branch_subscription_plan_appointments_on_workflow_status"
  end

  create_table "branch_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_tag_appointments_on_branch_id"
    t.index ["business_type"], name: "index_branch_tag_appointments_on_business_type"
    t.index ["company_id", "branch_id", "tag_id"], name: "idx_branch_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_branch_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_branch_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_branch_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_branch_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_branch_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_branch_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["business_type"], name: "index_branches_on_business_type"
    t.index ["category_id"], name: "index_branches_on_category_id"
    t.index ["code"], name: "index_branches_on_code", unique: true
    t.index ["company_id"], name: "index_branches_on_company_id"
    t.index ["discarded_at"], name: "index_branches_on_discarded_at"
    t.index ["email"], name: "index_branches_on_email", unique: true
    t.index ["external_id"], name: "index_branches_on_external_id"
    t.index ["lifecycle_status"], name: "index_branches_on_lifecycle_status"
    t.index ["parent_branch_id"], name: "index_branches_on_parent_branch_id"
    t.index ["property_mapping_id"], name: "index_branches_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_branches_on_workflow_status"
  end

  create_table "brand_profiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "logo_stored_file_id"
    t.string "domain", null: false
    t.string "display_name"
    t.string "primary_color"
    t.string "email_from"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_brand_profiles_on_business_type"
    t.index ["company_id", "is_active"], name: "index_brand_profiles_on_company_id_and_is_active"
    t.index ["company_id"], name: "index_brand_profiles_on_company_id"
    t.index ["discarded_at"], name: "index_brand_profiles_on_discarded_at"
    t.index ["domain"], name: "index_brand_profiles_on_domain", unique: true
    t.index ["lifecycle_status"], name: "index_brand_profiles_on_lifecycle_status"
    t.index ["logo_stored_file_id"], name: "index_brand_profiles_on_logo_stored_file_id"
    t.index ["workflow_status"], name: "index_brand_profiles_on_workflow_status"
  end

  create_table "brand_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "brand_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_brand_tag_appointments_on_brand_id"
    t.index ["business_type"], name: "index_brand_tag_appointments_on_business_type"
    t.index ["company_id", "brand_id", "tag_id"], name: "idx_brand_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_brand_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_brand_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_brand_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_brand_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_brand_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_brand_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["business_type"], name: "index_brands_on_business_type"
    t.index ["category_id"], name: "index_brands_on_category_id"
    t.index ["code"], name: "index_brands_on_code", unique: true
    t.index ["company_id"], name: "index_brands_on_company_id"
    t.index ["discarded_at"], name: "index_brands_on_discarded_at"
    t.index ["email"], name: "index_brands_on_email", unique: true
    t.index ["external_id"], name: "index_brands_on_external_id"
    t.index ["lifecycle_status"], name: "index_brands_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_brands_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_brands_on_workflow_status"
  end

  create_table "budget_lines", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "budget_id", null: false
    t.uuid "ledger_account_id", null: false
    t.date "period_month", null: false
    t.bigint "amount_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "ledger_account_id", "period_month"], name: "idx_budget_lines_unique", unique: true
    t.index ["budget_id"], name: "index_budget_lines_on_budget_id"
    t.index ["business_type"], name: "index_budget_lines_on_business_type"
    t.index ["company_id"], name: "index_budget_lines_on_company_id"
    t.index ["discarded_at"], name: "index_budget_lines_on_discarded_at"
    t.index ["ledger_account_id"], name: "index_budget_lines_on_ledger_account_id"
    t.index ["lifecycle_status"], name: "index_budget_lines_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_budget_lines_on_workflow_status"
  end

  create_table "budgets", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "cost_center_id"
    t.uuid "fiscal_period_id"
    t.uuid "workflow_step_id"
    t.string "name", null: false
    t.text "description"
    t.integer "budget_scope", default: 0, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_budgets_on_branch_id"
    t.index ["business_type"], name: "index_budgets_on_business_type"
    t.index ["company_id", "budget_scope"], name: "index_budgets_on_company_id_and_budget_scope"
    t.index ["company_id", "name"], name: "index_budgets_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_budgets_on_company_id"
    t.index ["cost_center_id"], name: "index_budgets_on_cost_center_id"
    t.index ["discarded_at"], name: "index_budgets_on_discarded_at"
    t.index ["fiscal_period_id"], name: "index_budgets_on_fiscal_period_id"
    t.index ["lifecycle_status"], name: "index_budgets_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_budgets_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_budgets_on_workflow_step_id"
  end

  create_table "cart_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "cart_id", null: false
    t.uuid "employee_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_cart_employee_appointments_on_business_type"
    t.index ["cart_id"], name: "index_cart_employee_appointments_on_cart_id"
    t.index ["company_id", "cart_id", "employee_id"], name: "idx_cart_employee_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_cart_employee_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_cart_employee_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_cart_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_cart_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_cart_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_cart_employee_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_cart_groups_on_branch_id"
    t.index ["business_type"], name: "index_cart_groups_on_business_type"
    t.index ["category_id"], name: "index_cart_groups_on_category_id"
    t.index ["code"], name: "index_cart_groups_on_code", unique: true
    t.index ["company_id"], name: "index_cart_groups_on_company_id"
    t.index ["discarded_at"], name: "index_cart_groups_on_discarded_at"
    t.index ["email"], name: "index_cart_groups_on_email", unique: true
    t.index ["external_id"], name: "index_cart_groups_on_external_id"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_carts_on_branch_id"
    t.index ["business_type"], name: "index_carts_on_business_type"
    t.index ["cart_group_id"], name: "index_carts_on_cart_group_id"
    t.index ["category_id"], name: "index_carts_on_category_id"
    t.index ["code"], name: "index_carts_on_code", unique: true
    t.index ["company_id"], name: "index_carts_on_company_id"
    t.index ["discarded_at"], name: "index_carts_on_discarded_at"
    t.index ["email"], name: "index_carts_on_email", unique: true
    t.index ["external_id"], name: "index_carts_on_external_id"
    t.index ["lifecycle_status"], name: "index_carts_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_carts_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_carts_on_workflow_status"
  end

  create_table "categories", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_categories_on_external_id"
    t.index ["lifecycle_status"], name: "index_categories_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_categories_on_workflow_status"
  end

  create_table "channel_connections", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.integer "channel", default: 0, null: false
    t.string "name", null: false
    t.jsonb "credentials", default: {}
    t.integer "status", default: 0, null: false
    t.datetime "last_synced_at"
    t.datetime "connected_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_channel_connections_on_business_type"
    t.index ["company_id", "channel"], name: "index_channel_connections_on_company_id_and_channel"
    t.index ["company_id"], name: "index_channel_connections_on_company_id"
    t.index ["discarded_at"], name: "index_channel_connections_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_channel_connections_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_channel_connections_on_workflow_status"
  end

  create_table "channel_sync_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "channel_connection_id", null: false
    t.integer "direction", default: 0, null: false
    t.string "resource"
    t.integer "status", default: 0, null: false
    t.jsonb "payload", default: {}
    t.text "error_message"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "record_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_connection_id", "created_at"], name: "idx_on_channel_connection_id_created_at_1991b55fb9"
    t.index ["channel_connection_id"], name: "index_channel_sync_logs_on_channel_connection_id"
    t.index ["company_id"], name: "index_channel_sync_logs_on_company_id"
  end

  create_table "comment_mentions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "record_comment_id", null: false
    t.uuid "employee_id", null: false
    t.datetime "read_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_comment_mentions_on_business_type"
    t.index ["company_id"], name: "index_comment_mentions_on_company_id"
    t.index ["discarded_at"], name: "index_comment_mentions_on_discarded_at"
    t.index ["employee_id", "read_at"], name: "index_comment_mentions_on_employee_id_and_read_at"
    t.index ["employee_id"], name: "index_comment_mentions_on_employee_id"
    t.index ["lifecycle_status"], name: "index_comment_mentions_on_lifecycle_status"
    t.index ["record_comment_id", "employee_id"], name: "index_comment_mentions_on_record_comment_id_and_employee_id", unique: true
    t.index ["record_comment_id"], name: "index_comment_mentions_on_record_comment_id"
    t.index ["workflow_status"], name: "index_comment_mentions_on_workflow_status"
  end

  create_table "commission_entries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "commission_plan_id", null: false
    t.uuid "order_id"
    t.uuid "invoice_id"
    t.uuid "payroll_id"
    t.bigint "base_cents", default: 0, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_commission_entries_on_business_type"
    t.index ["commission_plan_id"], name: "index_commission_entries_on_commission_plan_id"
    t.index ["company_id", "employee_id", "status"], name: "idx_on_company_id_employee_id_status_96b0719fdb"
    t.index ["company_id"], name: "index_commission_entries_on_company_id"
    t.index ["discarded_at"], name: "index_commission_entries_on_discarded_at"
    t.index ["employee_id"], name: "index_commission_entries_on_employee_id"
    t.index ["invoice_id"], name: "index_commission_entries_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_commission_entries_on_lifecycle_status"
    t.index ["order_id"], name: "index_commission_entries_on_order_id"
    t.index ["payroll_id"], name: "index_commission_entries_on_payroll_id"
    t.index ["workflow_status"], name: "index_commission_entries_on_workflow_status"
  end

  create_table "commission_plans", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "applies_to_category_id"
    t.uuid "applies_to_employee_group_id"
    t.string "name", null: false
    t.text "description"
    t.integer "basis", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.date "effective_from"
    t.date "effective_to"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applies_to_category_id"], name: "index_commission_plans_on_applies_to_category_id"
    t.index ["applies_to_employee_group_id"], name: "index_commission_plans_on_applies_to_employee_group_id"
    t.index ["business_type"], name: "index_commission_plans_on_business_type"
    t.index ["company_id", "name"], name: "index_commission_plans_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_commission_plans_on_company_id"
    t.index ["discarded_at"], name: "index_commission_plans_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_commission_plans_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_commission_plans_on_workflow_status"
  end

  create_table "commission_tiers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "commission_plan_id", null: false
    t.bigint "from_cents", default: 0, null: false
    t.bigint "to_cents"
    t.integer "rate_bp", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_commission_tiers_on_business_type"
    t.index ["commission_plan_id", "from_cents"], name: "index_commission_tiers_on_commission_plan_id_and_from_cents", unique: true
    t.index ["commission_plan_id"], name: "index_commission_tiers_on_commission_plan_id"
    t.index ["company_id"], name: "index_commission_tiers_on_company_id"
    t.index ["discarded_at"], name: "index_commission_tiers_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_commission_tiers_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_commission_tiers_on_workflow_status"
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
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "base_currency", default: 840, null: false
    t.boolean "is_legal_entity", default: true, null: false
    t.index ["business_type"], name: "index_companies_on_business_type"
    t.index ["discarded_at"], name: "index_companies_on_discarded_at"
    t.index ["external_id"], name: "index_companies_on_external_id"
    t.index ["lifecycle_status"], name: "index_companies_on_lifecycle_status"
    t.index ["user_id"], name: "index_companies_on_user_id"
    t.index ["workflow_status"], name: "index_companies_on_workflow_status"
  end

  create_table "company_company_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "parent_company_id", null: false
    t.uuid "child_company_id", null: false
    t.integer "ownership_bp", default: 10000, null: false
    t.boolean "is_consolidated", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_company_company_appointments_on_business_type"
    t.index ["child_company_id"], name: "index_company_company_appointments_on_child_company_id"
    t.index ["discarded_at"], name: "index_company_company_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_company_company_appointments_on_lifecycle_status"
    t.index ["parent_company_id", "child_company_id"], name: "idx_company_company_unique", unique: true
    t.index ["parent_company_id"], name: "index_company_company_appointments_on_parent_company_id"
    t.index ["workflow_status"], name: "index_company_company_appointments_on_workflow_status"
  end

  create_table "company_daily_usages", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.date "usage_date", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.bigint "total_credits", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "usage_date"], name: "index_company_daily_usages_on_company_id_and_usage_date", unique: true
    t.index ["company_id"], name: "index_company_daily_usages_on_company_id"
    t.index ["discarded_at"], name: "index_company_daily_usages_on_discarded_at"
    t.index ["external_id"], name: "index_company_daily_usages_on_external_id"
  end

  create_table "company_entitlements", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "feature_key", null: false
    t.boolean "is_enabled", default: true, null: false
    t.integer "limit_value"
    t.datetime "expires_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_company_entitlements_on_business_type"
    t.index ["company_id", "feature_key"], name: "index_company_entitlements_on_company_id_and_feature_key", unique: true
    t.index ["company_id"], name: "index_company_entitlements_on_company_id"
    t.index ["discarded_at"], name: "index_company_entitlements_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_company_entitlements_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_company_entitlements_on_workflow_status"
  end

  create_table "company_invoices", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_order_id"
    t.string "invoice_number", null: false
    t.bigint "money_amount_cents", null: false
    t.bigint "credit_amount", null: false
    t.integer "currency", null: false
    t.integer "payment_status", default: 0, null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "created_at"], name: "index_company_invoices_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_company_invoices_on_company_id"
    t.index ["company_order_id"], name: "index_company_invoices_on_company_order_id", unique: true
    t.index ["discarded_at"], name: "index_company_invoices_on_discarded_at"
    t.index ["external_id"], name: "index_company_invoices_on_external_id"
    t.index ["invoice_number"], name: "index_company_invoices_on_invoice_number", unique: true
  end

  create_table "company_migration_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_migration_id", null: false
    t.uuid "company_id", null: false
    t.string "record_type"
    t.uuid "record_id"
    t.integer "action"
    t.jsonb "previous_state", default: {}
    t.string "resource"
    t.integer "source_row"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_migration_logs_on_company_id"
    t.index ["company_migration_id", "record_type", "record_id"], name: "idx_company_migration_logs_unique_record", unique: true
    t.index ["discarded_at"], name: "index_company_migration_logs_on_discarded_at"
    t.index ["record_type", "record_id"], name: "index_company_migration_logs_on_record_type_and_record_id"
  end

  create_table "company_migrations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "folder_id", null: false
    t.string "name", null: false
    t.string "target_resource"
    t.string "source_filename"
    t.bigint "source_file_size"
    t.jsonb "migration_mapping_config", default: {}
    t.jsonb "dry_run_result"
    t.integer "total_chunks", default: 0
    t.bigint "total_rows", default: 0
    t.bigint "processed_rows", default: 0
    t.bigint "created_rows", default: 0
    t.bigint "updated_rows", default: 0
    t.bigint "failed_rows", default: 0
    t.datetime "approved_at"
    t.datetime "completed_at"
    t.datetime "rolled_back_at"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_migrations_on_company_id"
    t.index ["discarded_at"], name: "index_company_migrations_on_discarded_at"
    t.index ["external_id"], name: "index_company_migrations_on_external_id"
    t.index ["folder_id"], name: "index_company_migrations_on_folder_id"
  end

  create_table "company_monthly_usages", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.date "usage_month", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.bigint "total_credits", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "usage_month"], name: "index_company_monthly_usages_on_company_id_and_usage_month", unique: true
    t.index ["company_id"], name: "index_company_monthly_usages_on_company_id"
    t.index ["discarded_at"], name: "index_company_monthly_usages_on_discarded_at"
    t.index ["external_id"], name: "index_company_monthly_usages_on_external_id"
  end

  create_table "company_orders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "user_id", null: false
    t.bigint "money_amount_cents", null: false
    t.bigint "credit_amount", null: false
    t.integer "currency", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "created_at"], name: "index_company_orders_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_company_orders_on_company_id"
    t.index ["discarded_at"], name: "index_company_orders_on_discarded_at"
    t.index ["external_id"], name: "index_company_orders_on_external_id"
    t.index ["user_id"], name: "index_company_orders_on_user_id"
  end

  create_table "company_payment_method_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "payment_method_id", null: false
    t.string "merchant_number"
    t.string "merchant_name"
    t.string "merchant_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_company_payment_method_appointments_on_business_type"
    t.index ["company_id", "payment_method_id"], name: "idx_company_payment_method_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_company_payment_method_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_company_payment_method_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_company_payment_method_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_payment_method_appointments_on_lifecycle_status"
    t.index ["payment_method_id"], name: "index_company_payment_method_appointments_on_payment_method_id"
    t.index ["workflow_status"], name: "index_company_payment_method_appointments_on_workflow_status"
  end

  create_table "company_payment_methods", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
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
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_company_payment_methods_on_business_type"
    t.index ["code"], name: "index_company_payment_methods_on_code", unique: true
    t.index ["discarded_at"], name: "index_company_payment_methods_on_discarded_at"
    t.index ["email"], name: "index_company_payment_methods_on_email", unique: true
    t.index ["external_id"], name: "index_company_payment_methods_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_payment_methods_on_lifecycle_status"
    t.index ["payment_mode"], name: "index_company_payment_methods_on_payment_mode"
    t.index ["workflow_status"], name: "index_company_payment_methods_on_workflow_status"
  end

  create_table "company_settings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.text "credential_1"
    t.text "credential_2"
    t.text "credential_3"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status", default: 0, null: false
    t.integer "business_type", null: false
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "business_type"], name: "idx_company_settings_single_active", unique: true, where: "((workflow_status = 1) AND (discarded_at IS NULL))"
    t.index ["company_id", "business_type"], name: "index_company_settings_on_company_id_and_business_type"
    t.index ["company_id", "name"], name: "idx_company_settings_name_uniq", unique: true
    t.index ["company_id"], name: "index_company_settings_on_company_id"
    t.index ["discarded_at"], name: "index_company_settings_on_discarded_at"
    t.index ["external_id"], name: "index_company_settings_on_external_id"
  end

  create_table "company_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_company_tag_appointments_on_business_type"
    t.index ["company_id", "tag_id"], name: "idx_company_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_company_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_company_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_company_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_company_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_company_tag_appointments_on_workflow_status"
  end

  create_table "company_ticket_comments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_ticket_id", null: false
    t.string "author_type", null: false
    t.uuid "author_id", null: false
    t.text "message", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_company_ticket_comments_on_author"
    t.index ["business_type"], name: "index_company_ticket_comments_on_business_type"
    t.index ["company_id", "created_at"], name: "index_company_ticket_comments_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_company_ticket_comments_on_company_id"
    t.index ["company_ticket_id", "created_at"], name: "idx_on_company_ticket_id_created_at_33559addf0"
    t.index ["company_ticket_id"], name: "index_company_ticket_comments_on_company_ticket_id"
    t.index ["discarded_at"], name: "index_company_ticket_comments_on_discarded_at"
    t.index ["external_id"], name: "index_company_ticket_comments_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_ticket_comments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_company_ticket_comments_on_workflow_status"
  end

  create_table "company_ticket_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_ticket_id", null: false
    t.string "actor_type"
    t.uuid "actor_id"
    t.integer "action", null: false
    t.string "from_status"
    t.string "to_status"
    t.text "note"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_company_ticket_logs_on_actor"
    t.index ["business_type"], name: "index_company_ticket_logs_on_business_type"
    t.index ["company_id"], name: "index_company_ticket_logs_on_company_id"
    t.index ["company_ticket_id", "created_at"], name: "index_company_ticket_logs_on_company_ticket_id_and_created_at"
    t.index ["company_ticket_id"], name: "index_company_ticket_logs_on_company_ticket_id"
    t.index ["discarded_at"], name: "index_company_ticket_logs_on_discarded_at"
    t.index ["external_id"], name: "index_company_ticket_logs_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_ticket_logs_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_company_ticket_logs_on_workflow_status"
  end

  create_table "company_tickets", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "assigned_user_id"
    t.string "name", null: false
    t.text "description"
    t.integer "ticket_category", default: 0, null: false
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "rate"
    t.datetime "first_responded_at"
    t.datetime "resolved_at"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sla_due_at"
    t.datetime "first_response_at"
    t.index ["assigned_user_id"], name: "index_company_tickets_on_assigned_user_id"
    t.index ["business_type"], name: "index_company_tickets_on_business_type"
    t.index ["company_id", "assigned_user_id"], name: "index_company_tickets_on_company_id_and_assigned_user_id"
    t.index ["company_id", "status"], name: "index_company_tickets_on_company_id_and_status"
    t.index ["company_id", "updated_at"], name: "index_company_tickets_on_company_id_and_updated_at"
    t.index ["company_id"], name: "index_company_tickets_on_company_id"
    t.index ["discarded_at"], name: "index_company_tickets_on_discarded_at"
    t.index ["employee_id"], name: "index_company_tickets_on_employee_id"
    t.index ["external_id"], name: "index_company_tickets_on_external_id"
    t.index ["lifecycle_status"], name: "index_company_tickets_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_company_tickets_on_workflow_status"
  end

  create_table "company_transactions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_invoice_id", null: false
    t.uuid "company_payment_method_id", null: false
    t.integer "transaction_type", null: false
    t.bigint "money_amount_cents", null: false
    t.integer "currency", null: false
    t.integer "status", default: 0, null: false
    t.string "gateway_reference"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "created_at"], name: "index_company_transactions_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_company_transactions_on_company_id"
    t.index ["company_invoice_id"], name: "index_company_transactions_on_company_invoice_id"
    t.index ["company_payment_method_id"], name: "index_company_transactions_on_company_payment_method_id"
    t.index ["discarded_at"], name: "index_company_transactions_on_discarded_at"
    t.index ["external_id"], name: "index_company_transactions_on_external_id"
    t.index ["gateway_reference"], name: "index_company_transactions_on_gateway_reference", unique: true
  end

  create_table "company_usage_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_wallet_id", null: false
    t.string "source_type"
    t.uuid "source_id"
    t.string "action_type", null: false
    t.bigint "change_amount", null: false
    t.bigint "balance_after", null: false
    t.text "description"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_company_usage_logs_on_action_type"
    t.index ["company_id"], name: "index_company_usage_logs_on_company_id"
    t.index ["company_wallet_id", "created_at"], name: "index_company_usage_logs_on_company_wallet_id_and_created_at"
    t.index ["company_wallet_id"], name: "index_company_usage_logs_on_company_wallet_id"
    t.index ["discarded_at"], name: "index_company_usage_logs_on_discarded_at"
    t.index ["external_id"], name: "index_company_usage_logs_on_external_id"
    t.index ["source_type", "source_id"], name: "index_company_usage_logs_on_source_type_and_source_id"
  end

  create_table "company_wallet_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "company_wallet_id", null: false
    t.string "source_type"
    t.uuid "source_id"
    t.integer "change_type", null: false
    t.bigint "change_amount", null: false
    t.bigint "balance_before", null: false
    t.bigint "balance_after", null: false
    t.text "description"
    t.integer "balance_type"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_wallet_logs_on_company_id"
    t.index ["company_wallet_id", "created_at"], name: "index_company_wallet_logs_on_company_wallet_id_and_created_at"
    t.index ["company_wallet_id"], name: "index_company_wallet_logs_on_company_wallet_id"
    t.index ["discarded_at"], name: "index_company_wallet_logs_on_discarded_at"
    t.index ["external_id"], name: "index_company_wallet_logs_on_external_id"
    t.index ["source_type", "source_id"], name: "index_company_wallet_logs_on_source_type_and_source_id"
  end

  create_table "company_wallets", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "walletable_type", null: false
    t.uuid "walletable_id", null: false
    t.bigint "main_credit_balance", default: 0, null: false
    t.bigint "promo_credit_balance", default: 0, null: false
    t.datetime "usage_logging_until"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_wallets_on_company_id", unique: true
    t.index ["discarded_at"], name: "index_company_wallets_on_discarded_at"
    t.index ["external_id"], name: "index_company_wallets_on_external_id"
    t.index ["walletable_type", "walletable_id"], name: "index_company_wallets_on_walletable_type_and_walletable_id"
  end

  create_table "cost_centers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "parent_id"
    t.uuid "branch_id"
    t.uuid "manager_employee_id"
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_cost_centers_on_branch_id"
    t.index ["business_type"], name: "index_cost_centers_on_business_type"
    t.index ["company_id", "code"], name: "index_cost_centers_on_company_id_and_code", unique: true
    t.index ["company_id", "parent_id"], name: "index_cost_centers_on_company_id_and_parent_id"
    t.index ["company_id"], name: "index_cost_centers_on_company_id"
    t.index ["discarded_at"], name: "index_cost_centers_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_cost_centers_on_lifecycle_status"
    t.index ["manager_employee_id"], name: "index_cost_centers_on_manager_employee_id"
    t.index ["parent_id"], name: "index_cost_centers_on_parent_id"
    t.index ["workflow_status"], name: "index_cost_centers_on_workflow_status"
  end

  create_table "course_enrollments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "course_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "exam_id"
    t.integer "status", default: 0, null: false
    t.integer "progress_percent", default: 0, null: false
    t.date "started_on"
    t.date "completed_on"
    t.date "expires_on"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_course_enrollments_on_business_type"
    t.index ["company_id", "expires_on"], name: "index_course_enrollments_on_company_id_and_expires_on"
    t.index ["company_id"], name: "index_course_enrollments_on_company_id"
    t.index ["course_id", "employee_id"], name: "index_course_enrollments_on_course_id_and_employee_id", unique: true
    t.index ["course_id"], name: "index_course_enrollments_on_course_id"
    t.index ["discarded_at"], name: "index_course_enrollments_on_discarded_at"
    t.index ["employee_id"], name: "index_course_enrollments_on_employee_id"
    t.index ["exam_id"], name: "index_course_enrollments_on_exam_id"
    t.index ["lifecycle_status"], name: "index_course_enrollments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_course_enrollments_on_workflow_status"
  end

  create_table "course_lessons", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "course_id", null: false
    t.integer "position", default: 1, null: false
    t.string "title", null: false
    t.text "body_markdown"
    t.integer "duration_minutes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_course_lessons_on_business_type"
    t.index ["company_id"], name: "index_course_lessons_on_company_id"
    t.index ["course_id", "position"], name: "index_course_lessons_on_course_id_and_position", unique: true
    t.index ["course_id"], name: "index_course_lessons_on_course_id"
    t.index ["discarded_at"], name: "index_course_lessons_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_course_lessons_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_course_lessons_on_workflow_status"
  end

  create_table "courses", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_courses_on_business_type"
    t.index ["company_id", "name"], name: "index_courses_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_courses_on_company_id"
    t.index ["discarded_at"], name: "index_courses_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_courses_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_courses_on_workflow_status"
  end

  create_table "credit_profiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "reviewed_by_employee_id"
    t.bigint "limit_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.boolean "hold_orders", default: false, null: false
    t.datetime "reviewed_at"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_credit_profiles_on_business_type"
    t.index ["company_id", "customer_id"], name: "index_credit_profiles_on_company_id_and_customer_id", unique: true
    t.index ["company_id"], name: "index_credit_profiles_on_company_id"
    t.index ["customer_id"], name: "index_credit_profiles_on_customer_id"
    t.index ["discarded_at"], name: "index_credit_profiles_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_credit_profiles_on_lifecycle_status"
    t.index ["reviewed_by_employee_id"], name: "index_credit_profiles_on_reviewed_by_employee_id"
    t.index ["workflow_status"], name: "index_credit_profiles_on_workflow_status"
  end

  create_table "customer_customer_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "customer_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_customer_group_appointments_on_business_type"
    t.index ["company_id", "customer_id", "customer_group_id"], name: "idx_customer_customer_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_customer_group_appointments_on_company_id"
    t.index ["customer_group_id"], name: "idx_on_customer_group_id_d7aad9d09e"
    t.index ["customer_id"], name: "index_customer_customer_group_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_customer_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_customer_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_customer_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_customer_customer_group_appointments_on_workflow_status"
  end

  create_table "customer_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "employee_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_employee_appointments_on_business_type"
    t.index ["company_id", "customer_id", "employee_id"], name: "idx_customer_employee_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_employee_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_employee_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_employee_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_customer_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_customer_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_customer_employee_appointments_on_workflow_status"
  end

  create_table "customer_event_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "event_id", null: false
    t.string "role"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_event_appointments_on_business_type"
    t.index ["company_id", "customer_id", "event_id"], name: "idx_customer_event_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_event_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_event_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_event_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_customer_event_appointments_on_event_id"
    t.index ["external_id"], name: "index_customer_event_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_event_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_customer_event_appointments_on_workflow_status"
  end

  create_table "customer_group_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_group_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_group_role_appointments_on_business_type"
    t.index ["company_id", "customer_group_id", "role_id"], name: "idx_customer_group_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_group_role_appointments_on_company_id"
    t.index ["customer_group_id"], name: "index_customer_group_role_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_customer_group_role_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_group_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_group_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_customer_group_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_customer_group_role_appointments_on_workflow_status"
  end

  create_table "customer_group_service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_group_id", null: false
    t.uuid "service_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_group_service_appointments_on_business_type"
    t.index ["company_id", "customer_group_id", "service_id"], name: "idx_customer_group_service_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_group_service_appointments_on_company_id"
    t.index ["customer_group_id"], name: "index_customer_group_service_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_customer_group_service_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_group_service_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_group_service_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_customer_group_service_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_customer_group_service_appointments_on_workflow_status"
  end

  create_table "customer_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_group_tag_appointments_on_business_type"
    t.index ["company_id", "customer_group_id", "tag_id"], name: "idx_customer_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_group_tag_appointments_on_company_id"
    t.index ["customer_group_id"], name: "index_customer_group_tag_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_customer_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_group_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_customer_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_customer_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_customer_groups_on_branch_id"
    t.index ["business_type"], name: "index_customer_groups_on_business_type"
    t.index ["category_id"], name: "index_customer_groups_on_category_id"
    t.index ["code"], name: "index_customer_groups_on_code", unique: true
    t.index ["company_id"], name: "index_customer_groups_on_company_id"
    t.index ["discarded_at"], name: "index_customer_groups_on_discarded_at"
    t.index ["email"], name: "index_customer_groups_on_email", unique: true
    t.index ["external_id"], name: "index_customer_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_customer_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_customer_groups_on_workflow_status"
  end

  create_table "customer_membership_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "membership_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_membership_appointments_on_business_type"
    t.index ["company_id", "customer_id", "membership_id"], name: "idx_customer_membership_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_membership_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_membership_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_membership_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_membership_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_membership_appointments_on_lifecycle_status"
    t.index ["membership_id"], name: "index_customer_membership_appointments_on_membership_id"
    t.index ["workflow_status"], name: "index_customer_membership_appointments_on_workflow_status"
  end

  create_table "customer_profiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_customer_profiles_on_branch_id"
    t.index ["business_type"], name: "index_customer_profiles_on_business_type"
    t.index ["category_id"], name: "index_customer_profiles_on_category_id"
    t.index ["code"], name: "index_customer_profiles_on_code", unique: true
    t.index ["company_id", "customer_id"], name: "index_customer_profiles_on_company_id_and_customer_id"
    t.index ["company_id"], name: "index_customer_profiles_on_company_id"
    t.index ["customer_id", "name"], name: "idx_customer_profiles_on_customer_and_name", unique: true
    t.index ["customer_id"], name: "index_customer_profiles_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_profiles_on_discarded_at"
    t.index ["email"], name: "index_customer_profiles_on_email", unique: true
    t.index ["external_id"], name: "index_customer_profiles_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_profiles_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_customer_profiles_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_customer_profiles_on_workflow_status"
  end

  create_table "customer_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_role_appointments_on_business_type"
    t.index ["company_id", "customer_id", "role_id"], name: "idx_customer_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_role_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_role_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_role_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_customer_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_customer_role_appointments_on_workflow_status"
  end

  create_table "customer_service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "service_id", null: false
    t.integer "duration"
    t.datetime "start_at"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_service_appointments_on_business_type"
    t.index ["company_id", "customer_id", "service_id"], name: "idx_customer_service_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_service_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_service_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_service_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_service_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_service_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_customer_service_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_customer_service_appointments_on_workflow_status"
  end

  create_table "customer_subprofiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "customer_id", null: false
    t.uuid "customer_profile_id", null: false
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_customer_subprofiles_on_branch_id"
    t.index ["business_type"], name: "index_customer_subprofiles_on_business_type"
    t.index ["category_id"], name: "index_customer_subprofiles_on_category_id"
    t.index ["code"], name: "index_customer_subprofiles_on_code", unique: true
    t.index ["company_id", "customer_id"], name: "index_customer_subprofiles_on_company_id_and_customer_id"
    t.index ["company_id"], name: "index_customer_subprofiles_on_company_id"
    t.index ["customer_id"], name: "index_customer_subprofiles_on_customer_id"
    t.index ["customer_profile_id", "customer_id"], name: "idx_customer_subprofiles_on_profile_and_customer"
    t.index ["customer_profile_id", "name"], name: "idx_customer_subprofiles_on_profile_and_name", unique: true
    t.index ["customer_profile_id"], name: "index_customer_subprofiles_on_customer_profile_id"
    t.index ["discarded_at"], name: "index_customer_subprofiles_on_discarded_at"
    t.index ["email"], name: "index_customer_subprofiles_on_email", unique: true
    t.index ["external_id"], name: "index_customer_subprofiles_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_subprofiles_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_customer_subprofiles_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_customer_subprofiles_on_workflow_status"
  end

  create_table "customer_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_tag_appointments_on_business_type"
    t.index ["company_id", "customer_id", "tag_id"], name: "idx_customer_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_customer_tag_appointments_on_company_id"
    t.index ["customer_id"], name: "index_customer_tag_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_customer_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_customer_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_customer_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_customer_tag_appointments_on_workflow_status"
  end

  create_table "customer_user_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.datetime "revoked_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_customer_user_appointments_on_business_type"
    t.index ["company_id"], name: "index_customer_user_appointments_on_company_id"
    t.index ["customer_id", "user_id"], name: "index_customer_user_appointments_on_customer_id_and_user_id", unique: true
    t.index ["customer_id"], name: "index_customer_user_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_user_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_customer_user_appointments_on_lifecycle_status"
    t.index ["user_id"], name: "index_customer_user_appointments_on_user_id"
    t.index ["workflow_status"], name: "index_customer_user_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.uuid "payment_term_id"
    t.string "tax_id"
    t.string "vat_id"
    t.index ["branch_id"], name: "index_customers_on_branch_id"
    t.index ["business_type"], name: "index_customers_on_business_type"
    t.index ["category_id"], name: "index_customers_on_category_id"
    t.index ["code"], name: "index_customers_on_code", unique: true
    t.index ["company_id", "external_id"], name: "idx_customers_company_external_id_uniq", unique: true
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["external_id"], name: "index_customers_on_external_id"
    t.index ["lifecycle_status"], name: "index_customers_on_lifecycle_status"
    t.index ["payment_term_id"], name: "index_customers_on_payment_term_id"
    t.index ["property_mapping_id"], name: "index_customers_on_property_mapping_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
    t.index ["workflow_status"], name: "index_customers_on_workflow_status"
  end

  create_table "dashboards", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status", default: 1, null: false
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_dashboards_on_company_id_and_name", unique: true
    t.index ["company_id", "workflow_status"], name: "index_dashboards_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_dashboards_on_company_id"
    t.index ["discarded_at"], name: "index_dashboards_on_discarded_at"
  end

  create_table "data_exports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "requested_by_employee_id"
    t.uuid "stored_file_id"
    t.string "export_type", default: "full", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_data_exports_on_business_type"
    t.index ["company_id", "status"], name: "index_data_exports_on_company_id_and_status"
    t.index ["company_id"], name: "index_data_exports_on_company_id"
    t.index ["discarded_at"], name: "index_data_exports_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_data_exports_on_lifecycle_status"
    t.index ["requested_by_employee_id"], name: "index_data_exports_on_requested_by_employee_id"
    t.index ["stored_file_id"], name: "index_data_exports_on_stored_file_id"
    t.index ["workflow_status"], name: "index_data_exports_on_workflow_status"
  end

  create_table "data_retention_policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "resource_name", null: false
    t.integer "retention_days", default: 365, null: false
    t.integer "action", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_data_retention_policies_on_business_type"
    t.index ["company_id", "resource_name"], name: "index_data_retention_policies_on_company_id_and_resource_name", unique: true
    t.index ["company_id"], name: "index_data_retention_policies_on_company_id"
    t.index ["discarded_at"], name: "index_data_retention_policies_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_data_retention_policies_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_data_retention_policies_on_workflow_status"
  end

  create_table "data_subject_requests", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id"
    t.uuid "employee_id"
    t.uuid "user_id"
    t.integer "request_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at"
    t.datetime "completed_at"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_data_subject_requests_on_business_type"
    t.index ["company_id", "status"], name: "index_data_subject_requests_on_company_id_and_status"
    t.index ["company_id"], name: "index_data_subject_requests_on_company_id"
    t.index ["customer_id"], name: "index_data_subject_requests_on_customer_id"
    t.index ["discarded_at"], name: "index_data_subject_requests_on_discarded_at"
    t.index ["employee_id"], name: "index_data_subject_requests_on_employee_id"
    t.index ["lifecycle_status"], name: "index_data_subject_requests_on_lifecycle_status"
    t.index ["user_id"], name: "index_data_subject_requests_on_user_id"
    t.index ["workflow_status"], name: "index_data_subject_requests_on_workflow_status"
  end

  create_table "department_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "department_id", null: false
    t.uuid "employee_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_department_employee_appointments_on_business_type"
    t.index ["company_id", "department_id", "employee_id"], name: "idx_department_employee_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_department_employee_appointments_on_company_id"
    t.index ["department_id"], name: "index_department_employee_appointments_on_department_id"
    t.index ["discarded_at"], name: "index_department_employee_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_department_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_department_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_department_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_department_employee_appointments_on_workflow_status"
  end

  create_table "department_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "department_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_department_role_appointments_on_business_type"
    t.index ["company_id", "department_id", "role_id"], name: "idx_department_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_department_role_appointments_on_company_id"
    t.index ["department_id"], name: "index_department_role_appointments_on_department_id"
    t.index ["discarded_at"], name: "index_department_role_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_department_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_department_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_department_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_department_role_appointments_on_workflow_status"
  end

  create_table "department_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "department_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_department_tag_appointments_on_business_type"
    t.index ["company_id", "department_id", "tag_id"], name: "idx_department_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_department_tag_appointments_on_company_id"
    t.index ["department_id"], name: "index_department_tag_appointments_on_department_id"
    t.index ["discarded_at"], name: "index_department_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_department_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_department_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_department_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_department_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["business_type"], name: "index_departments_on_business_type"
    t.index ["category_id"], name: "index_departments_on_category_id"
    t.index ["code"], name: "index_departments_on_code", unique: true
    t.index ["company_id"], name: "index_departments_on_company_id"
    t.index ["discarded_at"], name: "index_departments_on_discarded_at"
    t.index ["email"], name: "index_departments_on_email", unique: true
    t.index ["external_id"], name: "index_departments_on_external_id"
    t.index ["lifecycle_status"], name: "index_departments_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_departments_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_departments_on_workflow_status"
  end

  create_table "depreciation_entries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "fixed_asset_id", null: false
    t.uuid "fiscal_period_id", null: false
    t.uuid "journal_entry_id"
    t.bigint "amount_cents", default: 0, null: false
    t.bigint "accumulated_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.datetime "posted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_depreciation_entries_on_company_id"
    t.index ["fiscal_period_id"], name: "index_depreciation_entries_on_fiscal_period_id"
    t.index ["fixed_asset_id", "fiscal_period_id"], name: "idx_on_fixed_asset_id_fiscal_period_id_136bac8c50", unique: true
    t.index ["fixed_asset_id"], name: "index_depreciation_entries_on_fixed_asset_id"
    t.index ["journal_entry_id"], name: "index_depreciation_entries_on_journal_entry_id"
  end

  create_table "disbursement_batches", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "stored_file_id"
    t.string "name", null: false
    t.date "payment_on", null: false
    t.string "bank_account"
    t.bigint "total_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_disbursement_batches_on_branch_id"
    t.index ["business_type"], name: "index_disbursement_batches_on_business_type"
    t.index ["company_id", "payment_on"], name: "index_disbursement_batches_on_company_id_and_payment_on"
    t.index ["company_id"], name: "index_disbursement_batches_on_company_id"
    t.index ["discarded_at"], name: "index_disbursement_batches_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_disbursement_batches_on_lifecycle_status"
    t.index ["stored_file_id"], name: "index_disbursement_batches_on_stored_file_id"
    t.index ["workflow_status"], name: "index_disbursement_batches_on_workflow_status"
  end

  create_table "discount_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "prefix"
    t.integer "discount_type", null: false
    t.integer "currency"
    t.integer "amount_cents"
    t.decimal "percentage", precision: 15, scale: 4
    t.integer "max_amount_cents"
    t.integer "total_budget_cents"
    t.integer "current_spent_cents", default: 0, null: false
    t.integer "campaign_status", default: 0, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_discount_groups_on_business_type"
    t.index ["code"], name: "index_discount_groups_on_code", unique: true
    t.index ["company_id", "campaign_status"], name: "index_discount_groups_on_company_id_and_campaign_status"
    t.index ["company_id"], name: "index_discount_groups_on_company_id"
    t.index ["discarded_at"], name: "index_discount_groups_on_discarded_at"
    t.index ["external_id"], name: "index_discount_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_discount_groups_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_discount_groups_on_workflow_status"
  end

  create_table "discounts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "discount_group_id", null: false
    t.uuid "order_id"
    t.uuid "invoice_id"
    t.uuid "customer_id"
    t.uuid "employee_id"
    t.string "code", null: false
    t.integer "status", default: 0, null: false
    t.integer "amount_cents"
    t.datetime "used_at"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_discounts_on_business_type"
    t.index ["company_id", "code"], name: "index_discounts_on_company_id_and_code", unique: true
    t.index ["company_id"], name: "index_discounts_on_company_id"
    t.index ["customer_id"], name: "index_discounts_on_customer_id"
    t.index ["discarded_at"], name: "index_discounts_on_discarded_at"
    t.index ["discount_group_id", "status"], name: "index_discounts_on_discount_group_id_and_status"
    t.index ["discount_group_id"], name: "index_discounts_on_discount_group_id"
    t.index ["employee_id"], name: "index_discounts_on_employee_id"
    t.index ["external_id"], name: "index_discounts_on_external_id"
    t.index ["invoice_id"], name: "index_discounts_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_discounts_on_lifecycle_status"
    t.index ["order_id"], name: "index_discounts_on_order_id"
    t.index ["status"], name: "index_discounts_on_status"
    t.index ["workflow_status"], name: "index_discounts_on_workflow_status"
  end

  create_table "document_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "document_id", null: false
    t.uuid "employee_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_document_employee_appointments_on_business_type"
    t.index ["company_id", "document_id", "employee_id"], name: "idx_document_employee_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_document_employee_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_document_employee_appointments_on_discarded_at"
    t.index ["document_id"], name: "index_document_employee_appointments_on_document_id"
    t.index ["employee_id"], name: "index_document_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_document_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_document_employee_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_document_employee_appointments_on_workflow_status"
  end

  create_table "document_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "document_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_document_tag_appointments_on_business_type"
    t.index ["company_id", "document_id", "tag_id"], name: "idx_document_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_document_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_document_tag_appointments_on_discarded_at"
    t.index ["document_id"], name: "index_document_tag_appointments_on_document_id"
    t.index ["external_id"], name: "index_document_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_document_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_document_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_document_tag_appointments_on_workflow_status"
  end

  create_table "documents", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.text "body_markdown"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_documents_on_external_id"
    t.index ["lifecycle_status"], name: "index_documents_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_documents_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_documents_on_workflow_status"
  end

  create_table "employee_employee_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "related_employee_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_employee_appointments_on_business_type"
    t.index ["company_id"], name: "index_employee_employee_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_employee_appointments_on_discarded_at"
    t.index ["employee_id", "related_employee_id"], name: "idx_employee_employee_appointments_uniq", unique: true
    t.index ["employee_id"], name: "index_employee_employee_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_employee_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_employee_appointments_on_lifecycle_status"
    t.index ["related_employee_id"], name: "index_employee_employee_appointments_on_related_employee_id"
    t.index ["workflow_status"], name: "index_employee_employee_appointments_on_workflow_status"
  end

  create_table "employee_employee_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "employee_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_employee_group_appointments_on_business_type"
    t.index ["company_id", "employee_id", "employee_group_id"], name: "idx_employee_employee_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_employee_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_employee_group_appointments_on_discarded_at"
    t.index ["employee_group_id"], name: "idx_on_employee_group_id_cdf25709e0"
    t.index ["employee_id"], name: "index_employee_employee_group_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_employee_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_employee_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_employee_group_appointments_on_workflow_status"
  end

  create_table "employee_event_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "event_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_event_appointments_on_business_type"
    t.index ["company_id", "employee_id", "event_id"], name: "idx_employee_event_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_event_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_event_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_event_appointments_on_employee_id"
    t.index ["event_id"], name: "index_employee_event_appointments_on_event_id"
    t.index ["external_id"], name: "index_employee_event_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_event_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_event_appointments_on_workflow_status"
  end

  create_table "employee_event_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "event_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_event_group_appointments_on_business_type"
    t.index ["company_id", "employee_id", "event_group_id"], name: "idx_employee_event_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_event_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_event_group_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_event_group_appointments_on_employee_id"
    t.index ["event_group_id"], name: "index_employee_event_group_appointments_on_event_group_id"
    t.index ["external_id"], name: "index_employee_event_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_event_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_event_group_appointments_on_workflow_status"
  end

  create_table "employee_exam_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "exam_id", null: false
    t.uuid "assigned_by_employee_id"
    t.uuid "graded_by_employee_id"
    t.integer "attempt_number", default: 1, null: false
    t.datetime "started_at"
    t.datetime "deadline_at"
    t.datetime "submitted_at"
    t.datetime "graded_at"
    t.integer "question_count", default: 0, null: false
    t.integer "correct_count", default: 0, null: false
    t.decimal "total_points", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "earned_points", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "score", precision: 5, scale: 2
    t.boolean "passed"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "lifecycle_status"
    t.integer "workflow_status", default: 0, null: false
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "employee_id", "exam_id", "attempt_number"], name: "idx_employee_exam_attempt_uniq", unique: true
    t.index ["company_id", "employee_id", "exam_id"], name: "idx_employee_exam_active_uniq", unique: true, where: "(workflow_status = ANY (ARRAY[0, 1]))"
    t.index ["company_id"], name: "index_employee_exam_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_exam_appointments_on_discarded_at"
    t.index ["employee_id", "workflow_status"], name: "idx_on_employee_id_workflow_status_d6d223d768"
    t.index ["employee_id"], name: "index_employee_exam_appointments_on_employee_id"
    t.index ["exam_id", "workflow_status"], name: "idx_on_exam_id_workflow_status_e8ec8d50b6"
    t.index ["exam_id"], name: "index_employee_exam_appointments_on_exam_id"
  end

  create_table "employee_facility_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "facility_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_facility_appointments_on_business_type"
    t.index ["company_id", "employee_id", "facility_id"], name: "idx_employee_facility_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_facility_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_facility_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_facility_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_facility_appointments_on_external_id"
    t.index ["facility_id"], name: "index_employee_facility_appointments_on_facility_id"
    t.index ["lifecycle_status"], name: "index_employee_facility_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_employee_facility_appointments_on_workflow_status"
  end

  create_table "employee_group_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_group_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_group_role_appointments_on_business_type"
    t.index ["company_id", "employee_group_id", "role_id"], name: "idx_employee_group_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_group_role_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_group_role_appointments_on_discarded_at"
    t.index ["employee_group_id"], name: "index_employee_group_role_appointments_on_employee_group_id"
    t.index ["external_id"], name: "index_employee_group_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_group_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_employee_group_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_employee_group_role_appointments_on_workflow_status"
  end

  create_table "employee_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_group_tag_appointments_on_business_type"
    t.index ["company_id", "employee_group_id", "tag_id"], name: "idx_employee_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_group_tag_appointments_on_discarded_at"
    t.index ["employee_group_id"], name: "index_employee_group_tag_appointments_on_employee_group_id"
    t.index ["external_id"], name: "index_employee_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_group_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_employee_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_employee_group_tag_appointments_on_workflow_status"
  end

  create_table "employee_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.uuid "manager_id"
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_employee_groups_on_branch_id"
    t.index ["business_type"], name: "index_employee_groups_on_business_type"
    t.index ["category_id"], name: "index_employee_groups_on_category_id"
    t.index ["code"], name: "index_employee_groups_on_code", unique: true
    t.index ["company_id"], name: "index_employee_groups_on_company_id"
    t.index ["discarded_at"], name: "index_employee_groups_on_discarded_at"
    t.index ["email"], name: "index_employee_groups_on_email", unique: true
    t.index ["external_id"], name: "index_employee_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_groups_on_lifecycle_status"
    t.index ["manager_id"], name: "index_employee_groups_on_manager_id"
    t.index ["property_mapping_id"], name: "index_employee_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_employee_groups_on_workflow_status"
  end

  create_table "employee_manager_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "manager_employee_id", null: false
    t.integer "relationship_type", default: 0, null: false
    t.date "effective_from"
    t.date "effective_to"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_manager_appointments_on_business_type"
    t.index ["company_id"], name: "index_employee_manager_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_manager_appointments_on_discarded_at"
    t.index ["employee_id", "manager_employee_id", "relationship_type"], name: "idx_employee_manager_unique", unique: true
    t.index ["employee_id"], name: "index_employee_manager_appointments_on_employee_id"
    t.index ["lifecycle_status"], name: "index_employee_manager_appointments_on_lifecycle_status"
    t.index ["manager_employee_id"], name: "index_employee_manager_appointments_on_manager_employee_id"
    t.index ["workflow_status"], name: "index_employee_manager_appointments_on_workflow_status"
  end

  create_table "employee_notification_reads", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "notification_id", null: false
    t.datetime "read_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_notification_reads_on_business_type"
    t.index ["company_id", "employee_id"], name: "idx_emp_notif_reads_on_company_emp"
    t.index ["company_id"], name: "index_employee_notification_reads_on_company_id"
    t.index ["discarded_at"], name: "index_employee_notification_reads_on_discarded_at"
    t.index ["employee_id", "notification_id"], name: "idx_emp_notif_reads_on_emp_notif", unique: true
    t.index ["employee_id"], name: "index_employee_notification_reads_on_employee_id"
    t.index ["external_id"], name: "index_employee_notification_reads_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_notification_reads_on_lifecycle_status"
    t.index ["notification_id"], name: "index_employee_notification_reads_on_notification_id"
    t.index ["workflow_status"], name: "index_employee_notification_reads_on_workflow_status"
  end

  create_table "employee_notification_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "notification_tag_id", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_notification_tag_appointments_on_business_type"
    t.index ["company_id", "employee_id", "notification_tag_id"], name: "idx_emp_notif_tag_appt_on_company_emp_tag", unique: true
    t.index ["company_id"], name: "index_employee_notification_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_notification_tag_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_notification_tag_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_notification_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "idx_on_lifecycle_status_dfd29cf6d8"
    t.index ["notification_tag_id"], name: "idx_on_notification_tag_id_b5ef3943e8"
    t.index ["workflow_status"], name: "idx_on_workflow_status_1588449805"
  end

  create_table "employee_order_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "order_group_id", null: false
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_order_group_appointments_on_business_type"
    t.index ["company_id", "employee_id", "order_group_id"], name: "idx_employee_order_group_appointments_triple"
    t.index ["company_id"], name: "index_employee_order_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_order_group_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_order_group_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_order_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_order_group_appointments_on_lifecycle_status"
    t.index ["order_group_id"], name: "index_employee_order_group_appointments_on_order_group_id"
    t.index ["workflow_status"], name: "index_employee_order_group_appointments_on_workflow_status"
  end

  create_table "employee_product_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "product_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_product_appointments_on_business_type"
    t.index ["company_id", "employee_id", "product_id"], name: "idx_employee_product_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_product_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_product_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_product_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_product_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_product_appointments_on_lifecycle_status"
    t.index ["product_id"], name: "index_employee_product_appointments_on_product_id"
    t.index ["workflow_status"], name: "index_employee_product_appointments_on_workflow_status"
  end

  create_table "employee_profiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_employee_profiles_on_branch_id"
    t.index ["business_type"], name: "index_employee_profiles_on_business_type"
    t.index ["category_id"], name: "index_employee_profiles_on_category_id"
    t.index ["code"], name: "index_employee_profiles_on_code", unique: true
    t.index ["company_id", "employee_id"], name: "index_employee_profiles_on_company_id_and_employee_id"
    t.index ["company_id"], name: "index_employee_profiles_on_company_id"
    t.index ["discarded_at"], name: "index_employee_profiles_on_discarded_at"
    t.index ["email"], name: "index_employee_profiles_on_email", unique: true
    t.index ["employee_id", "name"], name: "idx_employee_profiles_on_employee_and_name", unique: true
    t.index ["employee_id"], name: "index_employee_profiles_on_employee_id"
    t.index ["external_id"], name: "index_employee_profiles_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_profiles_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_employee_profiles_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_employee_profiles_on_workflow_status"
  end

  create_table "employee_project_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "project_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_project_appointments_on_business_type"
    t.index ["company_id", "employee_id", "project_id"], name: "idx_employee_project_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_project_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_project_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_project_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_project_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_project_appointments_on_lifecycle_status"
    t.index ["project_id"], name: "index_employee_project_appointments_on_project_id"
    t.index ["workflow_status"], name: "index_employee_project_appointments_on_workflow_status"
  end

  create_table "employee_project_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "project_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_project_group_appointments_on_business_type"
    t.index ["company_id", "employee_id", "project_group_id"], name: "idx_employee_project_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_project_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_project_group_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_project_group_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_project_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_project_group_appointments_on_lifecycle_status"
    t.index ["project_group_id"], name: "index_employee_project_group_appointments_on_project_group_id"
    t.index ["workflow_status"], name: "index_employee_project_group_appointments_on_workflow_status"
  end

  create_table "employee_question_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_exam_appointment_id", null: false
    t.uuid "question_id", null: false
    t.integer "question_type", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "question_snapshot", default: {}, null: false
    t.jsonb "option_order", default: [], null: false
    t.jsonb "selected_option_ids", default: [], null: false
    t.text "text_answer"
    t.boolean "correct"
    t.decimal "points_possible", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "points_awarded", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "graded_at"
    t.uuid "graded_by_employee_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employee_question_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_question_appointments_on_discarded_at"
    t.index ["employee_exam_appointment_id", "question_id"], name: "idx_employee_question_attempt_uniq", unique: true
    t.index ["employee_exam_appointment_id"], name: "idx_on_employee_exam_appointment_id_46f73451d1"
    t.index ["question_id"], name: "index_employee_question_appointments_on_question_id"
  end

  create_table "employee_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_role_appointments_on_business_type"
    t.index ["company_id", "employee_id", "role_id"], name: "idx_employee_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_role_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_role_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_role_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_role_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_employee_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_employee_role_appointments_on_workflow_status"
  end

  create_table "employee_service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "service_id", null: false
    t.integer "duration"
    t.datetime "start_at"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_service_appointments_on_business_type"
    t.index ["company_id", "employee_id", "service_id"], name: "idx_employee_service_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_service_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_service_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_service_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_service_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_service_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_employee_service_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_employee_service_appointments_on_workflow_status"
  end

  create_table "employee_subprofiles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.uuid "employee_profile_id", null: false
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_employee_subprofiles_on_branch_id"
    t.index ["business_type"], name: "index_employee_subprofiles_on_business_type"
    t.index ["category_id"], name: "index_employee_subprofiles_on_category_id"
    t.index ["code"], name: "index_employee_subprofiles_on_code", unique: true
    t.index ["company_id", "employee_id"], name: "index_employee_subprofiles_on_company_id_and_employee_id"
    t.index ["company_id"], name: "index_employee_subprofiles_on_company_id"
    t.index ["discarded_at"], name: "index_employee_subprofiles_on_discarded_at"
    t.index ["email"], name: "index_employee_subprofiles_on_email", unique: true
    t.index ["employee_id"], name: "index_employee_subprofiles_on_employee_id"
    t.index ["employee_profile_id", "employee_id"], name: "idx_employee_subprofiles_on_profile_and_employee"
    t.index ["employee_profile_id", "name"], name: "idx_employee_subprofiles_on_profile_and_name", unique: true
    t.index ["employee_profile_id"], name: "index_employee_subprofiles_on_employee_profile_id"
    t.index ["external_id"], name: "index_employee_subprofiles_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_subprofiles_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_employee_subprofiles_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_employee_subprofiles_on_workflow_status"
  end

  create_table "employee_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_tag_appointments_on_business_type"
    t.index ["company_id", "employee_id", "tag_id"], name: "idx_employee_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_tag_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_tag_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_employee_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_employee_tag_appointments_on_workflow_status"
  end

  create_table "employee_task_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "task_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_task_appointments_on_business_type"
    t.index ["company_id", "employee_id", "task_id"], name: "idx_employee_task_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_task_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_task_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_task_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_task_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_task_appointments_on_lifecycle_status"
    t.index ["task_id"], name: "index_employee_task_appointments_on_task_id"
    t.index ["workflow_status"], name: "index_employee_task_appointments_on_workflow_status"
  end

  create_table "employee_task_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "task_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_employee_task_group_appointments_on_business_type"
    t.index ["company_id", "employee_id", "task_group_id"], name: "idx_employee_task_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_employee_task_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_employee_task_group_appointments_on_discarded_at"
    t.index ["employee_id"], name: "index_employee_task_group_appointments_on_employee_id"
    t.index ["external_id"], name: "index_employee_task_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_employee_task_group_appointments_on_lifecycle_status"
    t.index ["task_group_id"], name: "index_employee_task_group_appointments_on_task_group_id"
    t.index ["workflow_status"], name: "index_employee_task_group_appointments_on_workflow_status"
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
    t.bigint "monthly_salary_cents", default: 0, null: false
    t.bigint "monthly_allowance_cents", default: 0, null: false
    t.string "external_id"
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
    t.uuid "cost_center_id"
    t.uuid "job_opening_id"
    t.date "hire_date"
    t.date "termination_date"
    t.string "employment_type"
    t.string "bank_account"
    t.string "tax_id"
    t.index ["branch_id"], name: "index_employees_on_branch_id"
    t.index ["business_type"], name: "index_employees_on_business_type"
    t.index ["category_id"], name: "index_employees_on_category_id"
    t.index ["code"], name: "index_employees_on_code", unique: true
    t.index ["company_id", "termination_date"], name: "index_employees_on_company_id_and_termination_date"
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["cost_center_id"], name: "index_employees_on_cost_center_id"
    t.index ["discarded_at"], name: "index_employees_on_discarded_at"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["external_id"], name: "index_employees_on_external_id"
    t.index ["job_opening_id"], name: "index_employees_on_job_opening_id"
    t.index ["lifecycle_status"], name: "index_employees_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_employees_on_property_mapping_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
    t.index ["workflow_status"], name: "index_employees_on_workflow_status"
  end

  create_table "event_config_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_config_id"
    t.uuid "category_id"
    t.uuid "employee_id"
    t.integer "action", null: false
    t.string "employee_name"
    t.string "category_name"
    t.boolean "create_stock_pending"
    t.boolean "strict_stock_hold"
    t.boolean "create_order_on_complete"
    t.boolean "warn_on_facility_overlap"
    t.boolean "warn_on_host_overlap"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_event_config_logs_on_category_id"
    t.index ["company_id", "created_at"], name: "idx_event_config_logs_on_company_time"
    t.index ["company_id", "event_config_id", "created_at"], name: "idx_event_config_logs_on_config_time"
    t.index ["company_id"], name: "index_event_config_logs_on_company_id"
    t.index ["employee_id"], name: "index_event_config_logs_on_employee_id"
    t.index ["event_config_id"], name: "index_event_config_logs_on_event_config_id"
    t.index ["external_id"], name: "index_event_config_logs_on_external_id"
  end

  create_table "event_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.boolean "create_stock_pending", default: false, null: false
    t.boolean "strict_stock_hold", default: false, null: false
    t.boolean "create_order_on_complete", default: false, null: false
    t.boolean "warn_on_facility_overlap", default: true, null: false
    t.boolean "warn_on_host_overlap", default: true, null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_configs_on_business_type"
    t.index ["category_id"], name: "index_event_configs_on_category_id"
    t.index ["company_id", "category_id"], name: "idx_event_configs_company_category_uniq", unique: true
    t.index ["company_id"], name: "index_event_configs_on_company_id"
    t.index ["discarded_at"], name: "index_event_configs_on_discarded_at"
    t.index ["external_id"], name: "index_event_configs_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_configs_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_event_configs_on_workflow_status"
  end

  create_table "event_facility_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.uuid "facility_id", null: false
    t.string "role"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_facility_appointments_on_business_type"
    t.index ["company_id", "event_id", "facility_id"], name: "idx_event_facility_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_facility_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_facility_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_facility_appointments_on_event_id"
    t.index ["external_id"], name: "index_event_facility_appointments_on_external_id"
    t.index ["facility_id"], name: "index_event_facility_appointments_on_facility_id"
    t.index ["lifecycle_status"], name: "index_event_facility_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_event_facility_appointments_on_workflow_status"
  end

  create_table "event_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_group_tag_appointments_on_business_type"
    t.index ["company_id", "event_group_id", "tag_id"], name: "idx_event_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_group_tag_appointments_on_discarded_at"
    t.index ["event_group_id"], name: "index_event_group_tag_appointments_on_event_group_id"
    t.index ["external_id"], name: "index_event_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_group_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_event_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_event_group_tag_appointments_on_workflow_status"
  end

  create_table "event_groups", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_event_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_event_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_event_groups_on_workflow_status"
  end

  create_table "event_order_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.uuid "order_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_order_appointments_on_business_type"
    t.index ["company_id", "event_id", "order_id"], name: "idx_event_order_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_order_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_order_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_order_appointments_on_event_id"
    t.index ["external_id"], name: "index_event_order_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_order_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_event_order_appointments_on_order_id"
    t.index ["workflow_status"], name: "index_event_order_appointments_on_workflow_status"
  end

  create_table "event_service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.uuid "service_id", null: false
    t.string "role"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_service_appointments_on_business_type"
    t.index ["company_id", "event_id", "service_id"], name: "idx_event_service_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_service_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_service_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_service_appointments_on_event_id"
    t.index ["external_id"], name: "index_event_service_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_service_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_event_service_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_event_service_appointments_on_workflow_status"
  end

  create_table "event_stock_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.uuid "stock_id", null: false
    t.integer "quantity", default: 1, null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_stock_appointments_on_business_type"
    t.index ["company_id", "event_id", "stock_id"], name: "idx_event_stock_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_stock_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_stock_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_stock_appointments_on_event_id"
    t.index ["external_id"], name: "index_event_stock_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_stock_appointments_on_lifecycle_status"
    t.index ["stock_id"], name: "index_event_stock_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_event_stock_appointments_on_workflow_status"
  end

  create_table "event_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "event_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_event_tag_appointments_on_business_type"
    t.index ["company_id", "event_id", "tag_id"], name: "idx_event_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_event_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_event_tag_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_tag_appointments_on_event_id"
    t.index ["external_id"], name: "index_event_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_event_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_event_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_event_tag_appointments_on_workflow_status"
  end

  create_table "events", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "event_group_id"
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_events_on_branch_id"
    t.index ["business_type"], name: "index_events_on_business_type"
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
    t.index ["external_id"], name: "index_events_on_external_id"
    t.index ["lifecycle_status"], name: "index_events_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_events_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_events_on_workflow_status"
  end

  create_table "exam_question_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "exam_id", null: false
    t.uuid "question_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_exam_question_appointments_on_company_id"
    t.index ["exam_id", "position"], name: "index_exam_question_appointments_on_exam_id_and_position"
    t.index ["exam_id", "question_id"], name: "index_exam_question_appointments_on_exam_id_and_question_id", unique: true
    t.index ["exam_id"], name: "index_exam_question_appointments_on_exam_id"
    t.index ["question_id"], name: "index_exam_question_appointments_on_question_id"
  end

  create_table "exam_summaries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "exam_id", null: false
    t.integer "assigned_count", default: 0, null: false
    t.integer "started_count", default: 0, null: false
    t.integer "submitted_count", default: 0, null: false
    t.integer "graded_count", default: 0, null: false
    t.integer "passed_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.integer "pending_review_count", default: 0, null: false
    t.integer "expired_count", default: 0, null: false
    t.decimal "average_score", precision: 5, scale: 2
    t.decimal "highest_score", precision: 5, scale: 2
    t.decimal "lowest_score", precision: 5, scale: 2
    t.decimal "pass_rate", precision: 5, scale: 2
    t.jsonb "question_stats", default: {}, null: false
    t.datetime "computed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_exam_summaries_on_company_id"
    t.index ["exam_id"], name: "index_exam_summaries_on_exam_id", unique: true
  end

  create_table "exams", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "duration_minutes"
    t.decimal "passing_score", precision: 5, scale: 2, default: "70.0", null: false
    t.integer "max_attempts", default: 1
    t.boolean "shuffle_options", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status", default: 0, null: false
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_exams_on_company_id_and_name", unique: true
    t.index ["company_id", "workflow_status"], name: "index_exams_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_exams_on_company_id"
    t.index ["discarded_at"], name: "index_exams_on_discarded_at"
  end

  create_table "exchange_rates", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.integer "base_currency", null: false
    t.integer "quote_currency", null: false
    t.decimal "rate", precision: 18, scale: 10, null: false
    t.date "effective_on", null: false
    t.string "source"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_currency", "quote_currency", "effective_on"], name: "idx_on_base_currency_quote_currency_effective_on_69b4320091"
    t.index ["business_type"], name: "index_exchange_rates_on_business_type"
    t.index ["company_id", "base_currency", "quote_currency", "effective_on"], name: "idx_exchange_rates_pair", unique: true
    t.index ["company_id"], name: "index_exchange_rates_on_company_id"
    t.index ["discarded_at"], name: "index_exchange_rates_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_exchange_rates_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_exchange_rates_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_facilities_on_branch_id"
    t.index ["business_type"], name: "index_facilities_on_business_type"
    t.index ["category_id"], name: "index_facilities_on_category_id"
    t.index ["code"], name: "index_facilities_on_code", unique: true
    t.index ["company_id"], name: "index_facilities_on_company_id"
    t.index ["discarded_at"], name: "index_facilities_on_discarded_at"
    t.index ["email"], name: "index_facilities_on_email", unique: true
    t.index ["external_id"], name: "index_facilities_on_external_id"
    t.index ["lifecycle_status"], name: "index_facilities_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_facilities_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_facilities_on_workflow_status"
  end

  create_table "facility_facility_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_id", null: false
    t.uuid "facility_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_facility_facility_group_appointments_on_business_type"
    t.index ["company_id", "facility_id", "facility_group_id"], name: "idx_facility_facility_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_facility_facility_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_facility_facility_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_facility_facility_group_appointments_on_external_id"
    t.index ["facility_group_id"], name: "idx_on_facility_group_id_5bb31414b7"
    t.index ["facility_id"], name: "index_facility_facility_group_appointments_on_facility_id"
    t.index ["lifecycle_status"], name: "index_facility_facility_group_appointments_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_facility_facility_group_appointments_on_workflow_status"
  end

  create_table "facility_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_facility_group_tag_appointments_on_business_type"
    t.index ["company_id", "facility_group_id", "tag_id"], name: "idx_facility_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_facility_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_facility_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_facility_group_tag_appointments_on_external_id"
    t.index ["facility_group_id"], name: "index_facility_group_tag_appointments_on_facility_group_id"
    t.index ["lifecycle_status"], name: "index_facility_group_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_facility_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_facility_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_facility_groups_on_branch_id"
    t.index ["business_type"], name: "index_facility_groups_on_business_type"
    t.index ["category_id"], name: "index_facility_groups_on_category_id"
    t.index ["code"], name: "index_facility_groups_on_code", unique: true
    t.index ["company_id"], name: "index_facility_groups_on_company_id"
    t.index ["discarded_at"], name: "index_facility_groups_on_discarded_at"
    t.index ["email"], name: "index_facility_groups_on_email", unique: true
    t.index ["external_id"], name: "index_facility_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_facility_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_facility_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_facility_groups_on_workflow_status"
  end

  create_table "facility_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_facility_tag_appointments_on_business_type"
    t.index ["company_id", "facility_id", "tag_id"], name: "idx_facility_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_facility_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_facility_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_facility_tag_appointments_on_external_id"
    t.index ["facility_id"], name: "index_facility_tag_appointments_on_facility_id"
    t.index ["lifecycle_status"], name: "index_facility_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_facility_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_facility_tag_appointments_on_workflow_status"
  end

  create_table "fiscal_periods", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.integer "fiscal_year", null: false
    t.integer "period_no", null: false
    t.string "name"
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "closed_at"
    t.uuid "closed_by_employee_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_fiscal_periods_on_business_type"
    t.index ["closed_by_employee_id"], name: "index_fiscal_periods_on_closed_by_employee_id"
    t.index ["company_id", "fiscal_year", "period_no"], name: "idx_on_company_id_fiscal_year_period_no_6966eeb7d0", unique: true
    t.index ["company_id", "starts_on", "ends_on"], name: "index_fiscal_periods_on_company_id_and_starts_on_and_ends_on"
    t.index ["company_id"], name: "index_fiscal_periods_on_company_id"
    t.index ["discarded_at"], name: "index_fiscal_periods_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_fiscal_periods_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_fiscal_periods_on_workflow_status"
  end

  create_table "fixed_assets", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "ledger_account_id"
    t.uuid "cost_center_id"
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.date "acquired_on", null: false
    t.bigint "cost_cents", default: 0, null: false
    t.bigint "salvage_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "useful_life_months", null: false
    t.integer "depreciation_method", default: 0, null: false
    t.date "disposed_on"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_fixed_assets_on_branch_id"
    t.index ["business_type"], name: "index_fixed_assets_on_business_type"
    t.index ["company_id", "code"], name: "index_fixed_assets_on_company_id_and_code", unique: true
    t.index ["company_id", "disposed_on"], name: "index_fixed_assets_on_company_id_and_disposed_on"
    t.index ["company_id"], name: "index_fixed_assets_on_company_id"
    t.index ["cost_center_id"], name: "index_fixed_assets_on_cost_center_id"
    t.index ["discarded_at"], name: "index_fixed_assets_on_discarded_at"
    t.index ["ledger_account_id"], name: "index_fixed_assets_on_ledger_account_id"
    t.index ["lifecycle_status"], name: "index_fixed_assets_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_fixed_assets_on_workflow_status"
  end

  create_table "folders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "parent_id"
    t.string "name", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "parent_id", "name"], name: "idx_folders_parent_name_uniq", unique: true
    t.index ["company_id", "parent_id"], name: "index_folders_on_company_id_and_parent_id"
    t.index ["company_id"], name: "index_folders_on_company_id"
    t.index ["discarded_at"], name: "index_folders_on_discarded_at"
    t.index ["external_id"], name: "index_folders_on_external_id"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
  end

  create_table "idempotency_keys", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "key", null: false
    t.string "request_digest", null: false
    t.jsonb "response", default: {}
    t.integer "response_status", default: 200, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "key"], name: "index_idempotency_keys_on_company_id_and_key", unique: true
    t.index ["company_id"], name: "index_idempotency_keys_on_company_id"
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
  end

  create_table "identity_providers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.integer "provider_type", default: 0, null: false
    t.string "name", null: false
    t.jsonb "domains", default: []
    t.string "client_id"
    t.string "client_secret"
    t.string "metadata_url"
    t.boolean "is_enforced", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_identity_providers_on_business_type"
    t.index ["company_id", "is_active"], name: "index_identity_providers_on_company_id_and_is_active"
    t.index ["company_id"], name: "index_identity_providers_on_company_id"
    t.index ["discarded_at"], name: "index_identity_providers_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_identity_providers_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_identity_providers_on_workflow_status"
  end

  create_table "import_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "import_id", null: false
    t.uuid "company_id", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.integer "action", null: false
    t.integer "source_row"
    t.jsonb "previous_state", default: {}, null: false
    t.string "resource"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_import_logs_on_company_id"
    t.index ["discarded_at"], name: "index_import_logs_on_discarded_at"
    t.index ["import_id", "record_type", "record_id"], name: "idx_import_logs_unique_record", unique: true
    t.index ["record_type", "record_id"], name: "index_import_logs_on_record_type_and_record_id"
  end

  create_table "imports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "folder_id", null: false
    t.uuid "creator_id"
    t.uuid "category_id"
    t.string "name", null: false
    t.text "description"
    t.string "target_table"
    t.string "target_model"
    t.jsonb "schema_snapshot", default: {}, null: false
    t.jsonb "dry_run_result"
    t.jsonb "error_samples", default: [], null: false
    t.string "source_filename"
    t.bigint "source_file_size"
    t.string "source_digest"
    t.bigint "total_rows", default: 0, null: false
    t.bigint "processed_rows", default: 0, null: false
    t.bigint "created_rows", default: 0, null: false
    t.bigint "failed_rows", default: 0, null: false
    t.datetime "approved_at"
    t.datetime "completed_at"
    t.datetime "rolled_back_at"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_imports_on_category_id"
    t.index ["company_id"], name: "index_imports_on_company_id"
    t.index ["creator_id"], name: "index_imports_on_creator_id"
    t.index ["discarded_at"], name: "index_imports_on_discarded_at"
    t.index ["folder_id"], name: "index_imports_on_folder_id"
    t.index ["target_table"], name: "index_imports_on_target_table"
    t.index ["workflow_status"], name: "index_imports_on_workflow_status"
  end

  create_table "invoice_reminders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "invoice_id", null: false
    t.integer "level", default: 1, null: false
    t.integer "channel", default: 0, null: false
    t.date "scheduled_on"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_invoice_reminders_on_business_type"
    t.index ["company_id", "scheduled_on"], name: "index_invoice_reminders_on_company_id_and_scheduled_on"
    t.index ["company_id"], name: "index_invoice_reminders_on_company_id"
    t.index ["discarded_at"], name: "index_invoice_reminders_on_discarded_at"
    t.index ["invoice_id", "level"], name: "index_invoice_reminders_on_invoice_id_and_level"
    t.index ["invoice_id"], name: "index_invoice_reminders_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_invoice_reminders_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_invoice_reminders_on_workflow_status"
  end

  create_table "invoice_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "invoice_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_invoice_tag_appointments_on_business_type"
    t.index ["company_id", "invoice_id", "tag_id"], name: "idx_invoice_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_invoice_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_invoice_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_invoice_tag_appointments_on_external_id"
    t.index ["invoice_id"], name: "index_invoice_tag_appointments_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_invoice_tag_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_invoice_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_invoice_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.uuid "payment_term_id"
    t.uuid "billing_schedule_id"
    t.uuid "credited_invoice_id"
    t.bigint "total_cents", default: 0, null: false
    t.bigint "tax_cents", default: 0, null: false
    t.decimal "currency_rate", precision: 18, scale: 10, default: "1.0"
    t.datetime "paid_at"
    t.integer "dunning_level", default: 0, null: false
    t.datetime "last_reminded_at"
    t.index ["billing_schedule_id"], name: "index_invoices_on_billing_schedule_id"
    t.index ["branch_id"], name: "index_invoices_on_branch_id"
    t.index ["business_type"], name: "index_invoices_on_business_type"
    t.index ["category_id"], name: "index_invoices_on_category_id"
    t.index ["code"], name: "index_invoices_on_code", unique: true
    t.index ["company_id", "dunning_level"], name: "index_invoices_on_company_id_and_dunning_level"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["credited_invoice_id"], name: "index_invoices_on_credited_invoice_id"
    t.index ["discarded_at"], name: "index_invoices_on_discarded_at"
    t.index ["email"], name: "index_invoices_on_email", unique: true
    t.index ["external_id"], name: "index_invoices_on_external_id"
    t.index ["lifecycle_status"], name: "index_invoices_on_lifecycle_status"
    t.index ["order_id"], name: "index_invoices_on_order_id"
    t.index ["payment_term_id"], name: "index_invoices_on_payment_term_id"
    t.index ["property_mapping_id"], name: "index_invoices_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_invoices_on_workflow_status"
  end

  create_table "job_openings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "department_id"
    t.string "title", null: false
    t.text "description"
    t.integer "openings_count", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.date "opened_on"
    t.date "closed_on"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_job_openings_on_branch_id"
    t.index ["business_type"], name: "index_job_openings_on_business_type"
    t.index ["company_id", "status"], name: "index_job_openings_on_company_id_and_status"
    t.index ["company_id"], name: "index_job_openings_on_company_id"
    t.index ["department_id"], name: "index_job_openings_on_department_id"
    t.index ["discarded_at"], name: "index_job_openings_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_job_openings_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_job_openings_on_workflow_status"
  end

  create_table "journal_entries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "fiscal_period_id"
    t.date "entry_date", null: false
    t.string "code"
    t.text "memo"
    t.string "source_type"
    t.uuid "source_id"
    t.string "event_key", null: false
    t.integer "status", default: 0, null: false
    t.datetime "posted_at"
    t.uuid "posted_by_employee_id"
    t.uuid "reversal_of_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_journal_entries_on_branch_id"
    t.index ["company_id", "entry_date"], name: "index_journal_entries_on_company_id_and_entry_date"
    t.index ["company_id", "source_type", "source_id", "event_key"], name: "idx_journal_entries_idempotency", unique: true
    t.index ["company_id"], name: "index_journal_entries_on_company_id"
    t.index ["fiscal_period_id"], name: "index_journal_entries_on_fiscal_period_id"
    t.index ["posted_by_employee_id"], name: "index_journal_entries_on_posted_by_employee_id"
    t.index ["reversal_of_id"], name: "index_journal_entries_on_reversal_of_id"
  end

  create_table "journal_lines", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "journal_entry_id", null: false
    t.uuid "ledger_account_id", null: false
    t.uuid "branch_id"
    t.uuid "department_id"
    t.uuid "cost_center_id"
    t.uuid "employee_id"
    t.uuid "customer_id"
    t.uuid "supplier_id"
    t.uuid "product_id"
    t.uuid "project_id"
    t.bigint "debit_cents", default: 0, null: false
    t.bigint "credit_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.decimal "fx_rate", precision: 18, scale: 10, default: "1.0"
    t.decimal "quantity", precision: 15, scale: 4
    t.string "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_journal_lines_on_branch_id"
    t.index ["company_id", "branch_id"], name: "index_journal_lines_on_company_id_and_branch_id"
    t.index ["company_id"], name: "index_journal_lines_on_company_id"
    t.index ["cost_center_id"], name: "index_journal_lines_on_cost_center_id"
    t.index ["customer_id"], name: "index_journal_lines_on_customer_id"
    t.index ["department_id"], name: "index_journal_lines_on_department_id"
    t.index ["employee_id"], name: "index_journal_lines_on_employee_id"
    t.index ["journal_entry_id"], name: "index_journal_lines_on_journal_entry_id"
    t.index ["ledger_account_id", "cost_center_id"], name: "index_journal_lines_on_ledger_account_id_and_cost_center_id"
    t.index ["ledger_account_id"], name: "index_journal_lines_on_ledger_account_id"
    t.index ["product_id"], name: "index_journal_lines_on_product_id"
    t.index ["project_id"], name: "index_journal_lines_on_project_id"
    t.index ["supplier_id"], name: "index_journal_lines_on_supplier_id"
  end

  create_table "kpi_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id"
    t.uuid "branch_id"
    t.uuid "department_id"
    t.uuid "role_id"
    t.string "name", null: false
    t.text "description"
    t.string "metric_key", null: false
    t.integer "direction", default: 0, null: false
    t.integer "period_type", default: 0, null: false
    t.decimal "target_value", precision: 15, scale: 2
    t.decimal "weight", precision: 8, scale: 2, default: "1.0", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_kpi_configs_on_branch_id"
    t.index ["category_id"], name: "index_kpi_configs_on_category_id"
    t.index ["company_id", "name"], name: "index_kpi_configs_on_company_id_and_name", unique: true
    t.index ["company_id", "workflow_status"], name: "index_kpi_configs_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_kpi_configs_on_company_id"
    t.index ["department_id"], name: "index_kpi_configs_on_department_id"
    t.index ["discarded_at"], name: "index_kpi_configs_on_discarded_at"
    t.index ["role_id"], name: "index_kpi_configs_on_role_id"
  end

  create_table "landed_cost_allocations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "landed_cost_charge_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "product_id", null: false
    t.decimal "quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.bigint "allocated_cents", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_landed_cost_allocations_on_business_type"
    t.index ["company_id"], name: "index_landed_cost_allocations_on_company_id"
    t.index ["discarded_at"], name: "index_landed_cost_allocations_on_discarded_at"
    t.index ["landed_cost_charge_id", "stock_id"], name: "idx_landed_cost_allocations_unique", unique: true
    t.index ["landed_cost_charge_id"], name: "index_landed_cost_allocations_on_landed_cost_charge_id"
    t.index ["lifecycle_status"], name: "index_landed_cost_allocations_on_lifecycle_status"
    t.index ["product_id"], name: "index_landed_cost_allocations_on_product_id"
    t.index ["stock_id"], name: "index_landed_cost_allocations_on_stock_id"
    t.index ["workflow_status"], name: "index_landed_cost_allocations_on_workflow_status"
  end

  create_table "landed_cost_charges", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_import_id", null: false
    t.uuid "supplier_id"
    t.integer "charge_type", default: 0, null: false
    t.bigint "amount_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "allocation_method", default: 1, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_landed_cost_charges_on_business_type"
    t.index ["company_id"], name: "index_landed_cost_charges_on_company_id"
    t.index ["discarded_at"], name: "index_landed_cost_charges_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_landed_cost_charges_on_lifecycle_status"
    t.index ["stock_import_id", "charge_type"], name: "index_landed_cost_charges_on_stock_import_id_and_charge_type"
    t.index ["stock_import_id"], name: "index_landed_cost_charges_on_stock_import_id"
    t.index ["supplier_id"], name: "index_landed_cost_charges_on_supplier_id"
    t.index ["workflow_status"], name: "index_landed_cost_charges_on_workflow_status"
  end

  create_table "ledger_accounts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "parent_id"
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "account_type", null: false
    t.integer "normal_balance", null: false
    t.boolean "is_control", default: false, null: false
    t.boolean "is_reconcilable", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "currency", default: 840
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_ledger_accounts_on_business_type"
    t.index ["company_id", "code"], name: "index_ledger_accounts_on_company_id_and_code", unique: true
    t.index ["company_id", "parent_id"], name: "index_ledger_accounts_on_company_id_and_parent_id"
    t.index ["company_id"], name: "index_ledger_accounts_on_company_id"
    t.index ["discarded_at"], name: "index_ledger_accounts_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_ledger_accounts_on_lifecycle_status"
    t.index ["parent_id"], name: "index_ledger_accounts_on_parent_id"
    t.index ["workflow_status"], name: "index_ledger_accounts_on_workflow_status"
  end

  create_table "loyalty_entries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "loyalty_program_id", null: false
    t.integer "points", default: 0, null: false
    t.integer "direction", default: 0, null: false
    t.string "source_type"
    t.uuid "source_id"
    t.date "expires_on"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "customer_id", "created_at"], name: "idx_on_company_id_customer_id_created_at_e03ac04b8f"
    t.index ["company_id"], name: "index_loyalty_entries_on_company_id"
    t.index ["customer_id"], name: "index_loyalty_entries_on_customer_id"
    t.index ["loyalty_program_id"], name: "index_loyalty_entries_on_loyalty_program_id"
  end

  create_table "loyalty_programs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "earn_rate_bp", default: 0, null: false
    t.integer "redeem_rate_bp", default: 0, null: false
    t.integer "expires_after_days"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_loyalty_programs_on_business_type"
    t.index ["company_id", "name"], name: "index_loyalty_programs_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_loyalty_programs_on_company_id"
    t.index ["discarded_at"], name: "index_loyalty_programs_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_loyalty_programs_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_loyalty_programs_on_workflow_status"
  end

  create_table "machine_readings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "work_center_id", null: false
    t.datetime "recorded_at", null: false
    t.decimal "usage_units", precision: 15, scale: 4, default: "0.0", null: false
    t.decimal "output_units", precision: 15, scale: 4, default: "0.0", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_machine_readings_on_company_id"
    t.index ["work_center_id", "recorded_at"], name: "index_machine_readings_on_work_center_id_and_recorded_at"
    t.index ["work_center_id"], name: "index_machine_readings_on_work_center_id"
  end

  create_table "maintenance_checks", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "maintenance_plan_id", null: false
    t.string "name", null: false
    t.text "instruction"
    t.integer "position", default: 1, null: false
    t.boolean "is_required", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_maintenance_checks_on_business_type"
    t.index ["company_id"], name: "index_maintenance_checks_on_company_id"
    t.index ["discarded_at"], name: "index_maintenance_checks_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_maintenance_checks_on_lifecycle_status"
    t.index ["maintenance_plan_id", "position"], name: "index_maintenance_checks_on_maintenance_plan_id_and_position", unique: true
    t.index ["maintenance_plan_id"], name: "index_maintenance_checks_on_maintenance_plan_id"
    t.index ["workflow_status"], name: "index_maintenance_checks_on_workflow_status"
  end

  create_table "maintenance_plans", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "facility_id"
    t.uuid "fixed_asset_id"
    t.string "name", null: false
    t.integer "interval_days"
    t.integer "interval_usage"
    t.date "next_due_on"
    t.date "last_done_on"
    t.integer "status", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_maintenance_plans_on_business_type"
    t.index ["company_id", "next_due_on"], name: "index_maintenance_plans_on_company_id_and_next_due_on"
    t.index ["company_id"], name: "index_maintenance_plans_on_company_id"
    t.index ["discarded_at"], name: "index_maintenance_plans_on_discarded_at"
    t.index ["facility_id"], name: "index_maintenance_plans_on_facility_id"
    t.index ["fixed_asset_id"], name: "index_maintenance_plans_on_fixed_asset_id"
    t.index ["lifecycle_status"], name: "index_maintenance_plans_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_maintenance_plans_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_memberships_on_branch_id"
    t.index ["business_type"], name: "index_memberships_on_business_type"
    t.index ["category_id"], name: "index_memberships_on_category_id"
    t.index ["code"], name: "index_memberships_on_code", unique: true
    t.index ["company_id"], name: "index_memberships_on_company_id"
    t.index ["discarded_at"], name: "index_memberships_on_discarded_at"
    t.index ["email"], name: "index_memberships_on_email", unique: true
    t.index ["external_id"], name: "index_memberships_on_external_id"
    t.index ["lifecycle_status"], name: "index_memberships_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_memberships_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_memberships_on_workflow_status"
  end

  create_table "mrp_runs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.date "run_on", null: false
    t.integer "horizon_days", default: 30, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "parameters", default: {}
    t.datetime "completed_at"
    t.text "error_message"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_mrp_runs_on_business_type"
    t.index ["company_id", "run_on"], name: "index_mrp_runs_on_company_id_and_run_on"
    t.index ["company_id"], name: "index_mrp_runs_on_company_id"
    t.index ["discarded_at"], name: "index_mrp_runs_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_mrp_runs_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_mrp_runs_on_workflow_status"
  end

  create_table "network_policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "cidr", null: false
    t.integer "scope", default: 0, null: false
    t.string "description"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_network_policies_on_business_type"
    t.index ["company_id", "scope", "is_active"], name: "index_network_policies_on_company_id_and_scope_and_is_active"
    t.index ["company_id"], name: "index_network_policies_on_company_id"
    t.index ["discarded_at"], name: "index_network_policies_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_network_policies_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_network_policies_on_workflow_status"
  end

  create_table "non_conformances", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "quality_inspection_id"
    t.uuid "production_order_id"
    t.uuid "stock_import_id"
    t.uuid "product_id"
    t.string "code"
    t.text "description"
    t.integer "severity", default: 0, null: false
    t.integer "disposition", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.datetime "resolved_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_non_conformances_on_business_type"
    t.index ["company_id", "status"], name: "index_non_conformances_on_company_id_and_status"
    t.index ["company_id"], name: "index_non_conformances_on_company_id"
    t.index ["discarded_at"], name: "index_non_conformances_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_non_conformances_on_lifecycle_status"
    t.index ["product_id", "severity"], name: "index_non_conformances_on_product_id_and_severity"
    t.index ["product_id"], name: "index_non_conformances_on_product_id"
    t.index ["production_order_id"], name: "index_non_conformances_on_production_order_id"
    t.index ["quality_inspection_id"], name: "index_non_conformances_on_quality_inspection_id"
    t.index ["stock_import_id"], name: "index_non_conformances_on_stock_import_id"
    t.index ["workflow_status"], name: "index_non_conformances_on_workflow_status"
  end

  create_table "notification_channels", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.integer "channel", default: 0, null: false
    t.string "name"
    t.jsonb "config", default: {}
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_notification_channels_on_business_type"
    t.index ["company_id", "channel"], name: "index_notification_channels_on_company_id_and_channel", unique: true
    t.index ["company_id"], name: "index_notification_channels_on_company_id"
    t.index ["discarded_at"], name: "index_notification_channels_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_notification_channels_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_notification_channels_on_workflow_status"
  end

  create_table "notification_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.datetime "last_read_all_at"
    t.jsonb "preferences", default: {}
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_notification_configs_on_business_type"
    t.index ["company_id", "employee_id"], name: "idx_notif_configs_on_company_emp", unique: true
    t.index ["company_id"], name: "index_notification_configs_on_company_id"
    t.index ["discarded_at"], name: "index_notification_configs_on_discarded_at"
    t.index ["employee_id"], name: "index_notification_configs_on_employee_id"
    t.index ["external_id"], name: "index_notification_configs_on_external_id"
    t.index ["lifecycle_status"], name: "index_notification_configs_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_notification_configs_on_workflow_status"
  end

  create_table "notification_deliveries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "notification_id", null: false
    t.uuid "notification_channel_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 1, null: false
    t.datetime "sent_at"
    t.integer "response_code"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_notification_deliveries_on_company_id"
    t.index ["notification_channel_id"], name: "index_notification_deliveries_on_notification_channel_id"
    t.index ["notification_id", "notification_channel_id"], name: "idx_on_notification_id_notification_channel_id_a341c2fce8"
    t.index ["notification_id"], name: "index_notification_deliveries_on_notification_id"
    t.index ["status", "created_at"], name: "index_notification_deliveries_on_status_and_created_at"
  end

  create_table "notification_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "notification_id", null: false
    t.uuid "notification_tag_id", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_notification_tag_appointments_on_business_type"
    t.index ["company_id", "notification_id", "notification_tag_id"], name: "idx_notif_tag_appt_on_company_notif_tag", unique: true
    t.index ["company_id"], name: "index_notification_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_notification_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_notification_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_notification_tag_appointments_on_lifecycle_status"
    t.index ["notification_id"], name: "index_notification_tag_appointments_on_notification_id"
    t.index ["notification_tag_id"], name: "index_notification_tag_appointments_on_notification_tag_id"
    t.index ["workflow_status"], name: "index_notification_tag_appointments_on_workflow_status"
  end

  create_table "notification_tags", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_notification_tags_on_business_type"
    t.index ["company_id", "name"], name: "index_notification_tags_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_notification_tags_on_company_id"
    t.index ["discarded_at"], name: "index_notification_tags_on_discarded_at"
    t.index ["external_id"], name: "index_notification_tags_on_external_id"
    t.index ["lifecycle_status"], name: "index_notification_tags_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_notification_tags_on_workflow_status"
  end

  create_table "notifications", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "severity", default: 0, null: false
    t.string "url"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject_type"
    t.uuid "subject_id"
    t.string "group_key"
    t.datetime "expires_at"
    t.index ["business_type"], name: "index_notifications_on_business_type"
    t.index ["company_id", "created_at"], name: "index_notifications_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["discarded_at"], name: "index_notifications_on_discarded_at"
    t.index ["external_id"], name: "index_notifications_on_external_id"
    t.index ["lifecycle_status"], name: "index_notifications_on_lifecycle_status"
    t.index ["subject_type", "subject_id"], name: "index_notifications_on_subject_type_and_subject_id"
    t.index ["workflow_status"], name: "index_notifications_on_workflow_status"
  end

  create_table "operation_warehouse_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "operation_id", null: false
    t.uuid "warehouse_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "operation_id", "warehouse_id"], name: "idx_operation_warehouse_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_operation_warehouse_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_operation_warehouse_appointments_on_discarded_at"
    t.index ["operation_id"], name: "index_operation_warehouse_appointments_on_operation_id"
    t.index ["warehouse_id"], name: "index_operation_warehouse_appointments_on_warehouse_id"
  end

  create_table "operations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.integer "operation_type", null: false
    t.integer "resolution"
    t.string "external_id"
    t.integer "lifecycle_status", null: false
    t.integer "workflow_status", null: false
    t.jsonb "metadata", null: false
    t.string "permission_resource_name", null: false
    t.datetime "expiration_date"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_operations_on_code", unique: true
    t.index ["company_id", "operation_type"], name: "index_operations_on_company_id_and_operation_type", unique: true
    t.index ["company_id"], name: "index_operations_on_company_id"
    t.index ["discarded_at"], name: "index_operations_on_discarded_at"
    t.index ["email"], name: "index_operations_on_email", unique: true
    t.index ["external_id"], name: "index_operations_on_external_id"
    t.index ["lifecycle_status"], name: "index_operations_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_operations_on_workflow_status"
  end

  create_table "order_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_group_tag_appointments_on_business_type"
    t.index ["company_id", "order_group_id", "tag_id"], name: "idx_order_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_order_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_group_tag_appointments_on_lifecycle_status"
    t.index ["order_group_id"], name: "index_order_group_tag_appointments_on_order_group_id"
    t.index ["tag_id"], name: "index_order_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_order_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_order_groups_on_branch_id"
    t.index ["business_type"], name: "index_order_groups_on_business_type"
    t.index ["category_id"], name: "index_order_groups_on_category_id"
    t.index ["code"], name: "index_order_groups_on_code", unique: true
    t.index ["company_id"], name: "index_order_groups_on_company_id"
    t.index ["customer_id"], name: "index_order_groups_on_customer_id"
    t.index ["discarded_at"], name: "index_order_groups_on_discarded_at"
    t.index ["email"], name: "index_order_groups_on_email", unique: true
    t.index ["external_id"], name: "index_order_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_order_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_order_groups_on_workflow_status"
  end

  create_table "order_pick_wave_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "pick_wave_id", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_pick_wave_appointments_on_business_type"
    t.index ["company_id"], name: "index_order_pick_wave_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_pick_wave_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_order_pick_wave_appointments_on_lifecycle_status"
    t.index ["order_id", "pick_wave_id"], name: "idx_order_pick_wave_unique", unique: true
    t.index ["order_id"], name: "index_order_pick_wave_appointments_on_order_id"
    t.index ["pick_wave_id"], name: "index_order_pick_wave_appointments_on_pick_wave_id"
    t.index ["workflow_status"], name: "index_order_pick_wave_appointments_on_workflow_status"
  end

  create_table "order_product_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "product_id", null: false
    t.uuid "stock_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_product_appointments_on_business_type"
    t.index ["company_id", "order_id", "product_id"], name: "idx_order_product_appointments_triple"
    t.index ["company_id"], name: "index_order_product_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_product_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_product_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_product_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_product_appointments_on_order_id"
    t.index ["product_id"], name: "index_order_product_appointments_on_product_id"
    t.index ["stock_id"], name: "index_order_product_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_order_product_appointments_on_workflow_status"
  end

  create_table "order_product_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "product_group_id", null: false
    t.uuid "stock_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_product_group_appointments_on_business_type"
    t.index ["company_id", "order_id", "product_group_id"], name: "idx_order_product_group_appointments_triple"
    t.index ["company_id"], name: "index_order_product_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_product_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_product_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_product_group_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_product_group_appointments_on_order_id"
    t.index ["product_group_id"], name: "index_order_product_group_appointments_on_product_group_id"
    t.index ["stock_id"], name: "index_order_product_group_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_order_product_group_appointments_on_workflow_status"
  end

  create_table "order_service_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "service_id", null: false
    t.uuid "stock_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_service_appointments_on_business_type"
    t.index ["company_id", "order_id", "service_id"], name: "idx_order_service_appointments_triple"
    t.index ["company_id"], name: "index_order_service_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_service_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_service_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_service_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_service_appointments_on_order_id"
    t.index ["service_id"], name: "index_order_service_appointments_on_service_id"
    t.index ["stock_id"], name: "index_order_service_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_order_service_appointments_on_workflow_status"
  end

  create_table "order_service_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "service_group_id", null: false
    t.uuid "stock_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_service_group_appointments_on_business_type"
    t.index ["company_id", "order_id", "service_group_id"], name: "idx_order_service_group_appointments_triple"
    t.index ["company_id"], name: "index_order_service_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_service_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_service_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_service_group_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_service_group_appointments_on_order_id"
    t.index ["service_group_id"], name: "index_order_service_group_appointments_on_service_group_id"
    t.index ["stock_id"], name: "index_order_service_group_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_order_service_group_appointments_on_workflow_status"
  end

  create_table "order_subscription_plan_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "subscription_plan_id", null: false
    t.uuid "stock_id"
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_subscription_plan_appointments_on_business_type"
    t.index ["company_id", "order_id", "subscription_plan_id"], name: "idx_order_subscription_plan_appointments_triple"
    t.index ["company_id"], name: "index_order_subscription_plan_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_subscription_plan_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_subscription_plan_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_subscription_plan_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_subscription_plan_appointments_on_order_id"
    t.index ["stock_id"], name: "index_order_subscription_plan_appointments_on_stock_id"
    t.index ["subscription_plan_id"], name: "idx_on_subscription_plan_id_e7356e6fd3"
    t.index ["workflow_status"], name: "index_order_subscription_plan_appointments_on_workflow_status"
  end

  create_table "order_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "order_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_order_tag_appointments_on_business_type"
    t.index ["company_id", "order_id", "tag_id"], name: "idx_order_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_order_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_order_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_order_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_order_tag_appointments_on_lifecycle_status"
    t.index ["order_id"], name: "index_order_tag_appointments_on_order_id"
    t.index ["tag_id"], name: "index_order_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_order_tag_appointments_on_workflow_status"
  end

  create_table "orders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "customer_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.uuid "employee_id"
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.string "external_id"
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
    t.uuid "payment_term_id"
    t.uuid "price_list_id"
    t.uuid "channel_connection_id"
    t.integer "document_type", default: 1, null: false
    t.bigint "total_cents", default: 0, null: false
    t.bigint "tax_cents", default: 0, null: false
    t.decimal "currency_rate", precision: 18, scale: 10, default: "1.0"
    t.datetime "converted_at"
    t.string "external_order_number"
    t.index ["branch_id"], name: "index_orders_on_branch_id"
    t.index ["business_type"], name: "index_orders_on_business_type"
    t.index ["category_id"], name: "index_orders_on_category_id"
    t.index ["channel_connection_id"], name: "index_orders_on_channel_connection_id"
    t.index ["code"], name: "index_orders_on_code", unique: true
    t.index ["company_id", "document_type"], name: "index_orders_on_company_id_and_document_type"
    t.index ["company_id", "employee_id", "created_at"], name: "index_orders_on_company_employee_created_at"
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["email"], name: "index_orders_on_email", unique: true
    t.index ["employee_id"], name: "index_orders_on_employee_id"
    t.index ["external_id"], name: "index_orders_on_external_id"
    t.index ["lifecycle_status"], name: "index_orders_on_lifecycle_status"
    t.index ["payment_term_id"], name: "index_orders_on_payment_term_id"
    t.index ["price_list_id"], name: "index_orders_on_price_list_id"
    t.index ["property_mapping_id"], name: "index_orders_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_orders_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_payment_methods_on_external_id"
    t.index ["lifecycle_status"], name: "index_payment_methods_on_lifecycle_status"
    t.index ["payment_mode"], name: "index_payment_methods_on_payment_mode"
    t.index ["workflow_status"], name: "index_payment_methods_on_workflow_status"
  end

  create_table "payment_terms", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "net_days", default: 0, null: false
    t.integer "discount_days"
    t.integer "discount_bp"
    t.boolean "is_default", default: false, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_payment_terms_on_business_type"
    t.index ["company_id", "name"], name: "index_payment_terms_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_payment_terms_on_company_id"
    t.index ["discarded_at"], name: "index_payment_terms_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_payment_terms_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_payment_terms_on_workflow_status"
  end

  create_table "payroll_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_payroll_configs_on_company_id", unique: true
  end

  create_table "payrolls", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "employee_id", null: false
    t.uuid "attendance_month_id"
    t.uuid "payroll_config_id"
    t.date "month", null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "currency", default: 840, null: false
    t.bigint "base_amount_cents", default: 0, null: false
    t.bigint "allowance_amount_cents", default: 0, null: false
    t.bigint "overtime_amount_cents", default: 0, null: false
    t.bigint "gross_amount_cents", default: 0, null: false
    t.bigint "tax_amount_cents", default: 0, null: false
    t.bigint "deduction_amount_cents", default: 0, null: false
    t.bigint "net_amount_cents", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "disbursement_batch_id"
    t.uuid "cost_center_id"
    t.datetime "approved_at"
    t.datetime "paid_at"
    t.index ["attendance_month_id"], name: "index_payrolls_on_attendance_month_id"
    t.index ["branch_id"], name: "index_payrolls_on_branch_id"
    t.index ["company_id", "employee_id", "month"], name: "index_payrolls_on_company_id_and_employee_id_and_month", unique: true
    t.index ["company_id", "paid_at"], name: "index_payrolls_on_company_id_and_paid_at"
    t.index ["company_id"], name: "index_payrolls_on_company_id"
    t.index ["cost_center_id"], name: "index_payrolls_on_cost_center_id"
    t.index ["disbursement_batch_id"], name: "index_payrolls_on_disbursement_batch_id"
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
    t.index ["month"], name: "index_payrolls_on_month"
    t.index ["payroll_config_id"], name: "index_payrolls_on_payroll_config_id"
  end

  create_table "permission_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "policy_id"
    t.uuid "role_id"
    t.uuid "policy_role_appointment_id"
    t.uuid "employee_id"
    t.integer "action", null: false
    t.string "employee_name"
    t.string "role_name"
    t.string "policy_name"
    t.string "resource_name"
    t.string "policy_action"
    t.integer "from_workflow_status"
    t.integer "to_workflow_status"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_permission_logs_on_business_type"
    t.index ["company_id", "created_at"], name: "index_permission_logs_on_company_id_and_created_at"
    t.index ["company_id", "policy_id", "created_at"], name: "idx_permission_logs_on_company_policy_time"
    t.index ["company_id", "role_id", "created_at"], name: "idx_permission_logs_on_company_role_time"
    t.index ["company_id"], name: "index_permission_logs_on_company_id"
    t.index ["discarded_at"], name: "index_permission_logs_on_discarded_at"
    t.index ["employee_id"], name: "index_permission_logs_on_employee_id"
    t.index ["external_id"], name: "index_permission_logs_on_external_id"
    t.index ["lifecycle_status"], name: "index_permission_logs_on_lifecycle_status"
    t.index ["policy_id"], name: "index_permission_logs_on_policy_id"
    t.index ["policy_role_appointment_id"], name: "index_permission_logs_on_policy_role_appointment_id"
    t.index ["role_id"], name: "index_permission_logs_on_role_id"
    t.index ["workflow_status"], name: "index_permission_logs_on_workflow_status"
  end

  create_table "pick_tasks", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "pick_wave_id", null: false
    t.uuid "order_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "stock_lot_id"
    t.uuid "storage_location_id"
    t.uuid "assigned_employee_id"
    t.integer "quantity", default: 0, null: false
    t.integer "picked_quantity", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "completed_at"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_employee_id", "status"], name: "index_pick_tasks_on_assigned_employee_id_and_status"
    t.index ["assigned_employee_id"], name: "index_pick_tasks_on_assigned_employee_id"
    t.index ["business_type"], name: "index_pick_tasks_on_business_type"
    t.index ["company_id"], name: "index_pick_tasks_on_company_id"
    t.index ["discarded_at"], name: "index_pick_tasks_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_pick_tasks_on_lifecycle_status"
    t.index ["order_id"], name: "index_pick_tasks_on_order_id"
    t.index ["pick_wave_id", "status"], name: "index_pick_tasks_on_pick_wave_id_and_status"
    t.index ["pick_wave_id"], name: "index_pick_tasks_on_pick_wave_id"
    t.index ["stock_id"], name: "index_pick_tasks_on_stock_id"
    t.index ["stock_lot_id"], name: "index_pick_tasks_on_stock_lot_id"
    t.index ["storage_location_id"], name: "index_pick_tasks_on_storage_location_id"
    t.index ["workflow_status"], name: "index_pick_tasks_on_workflow_status"
  end

  create_table "pick_waves", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "created_by_employee_id"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "released_at"
    t.datetime "completed_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_pick_waves_on_business_type"
    t.index ["company_id", "status"], name: "index_pick_waves_on_company_id_and_status"
    t.index ["company_id"], name: "index_pick_waves_on_company_id"
    t.index ["created_by_employee_id"], name: "index_pick_waves_on_created_by_employee_id"
    t.index ["discarded_at"], name: "index_pick_waves_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_pick_waves_on_lifecycle_status"
    t.index ["warehouse_id", "created_at"], name: "index_pick_waves_on_warehouse_id_and_created_at"
    t.index ["warehouse_id"], name: "index_pick_waves_on_warehouse_id"
    t.index ["workflow_status"], name: "index_pick_waves_on_workflow_status"
  end

  create_table "policies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "resource"
    t.string "action"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_policies_on_external_id"
    t.index ["lifecycle_status"], name: "index_policies_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_policies_on_workflow_status"
  end

  create_table "policy_role_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "policy_id", null: false
    t.uuid "role_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_policy_role_appointments_on_business_type"
    t.index ["company_id", "policy_id", "role_id"], name: "idx_policy_role_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_policy_role_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_policy_role_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_policy_role_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_policy_role_appointments_on_lifecycle_status"
    t.index ["policy_id"], name: "index_policy_role_appointments_on_policy_id"
    t.index ["role_id"], name: "index_policy_role_appointments_on_role_id"
    t.index ["workflow_status"], name: "index_policy_role_appointments_on_workflow_status"
  end

  create_table "posting_rules", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "debit_ledger_account_id", null: false
    t.uuid "credit_ledger_account_id", null: false
    t.string "event_key", null: false
    t.string "name"
    t.integer "priority", default: 0, null: false
    t.jsonb "conditions", default: {}
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_posting_rules_on_business_type"
    t.index ["company_id", "event_key", "priority"], name: "index_posting_rules_on_company_id_and_event_key_and_priority", unique: true
    t.index ["company_id"], name: "index_posting_rules_on_company_id"
    t.index ["credit_ledger_account_id"], name: "index_posting_rules_on_credit_ledger_account_id"
    t.index ["debit_ledger_account_id"], name: "index_posting_rules_on_debit_ledger_account_id"
    t.index ["discarded_at"], name: "index_posting_rules_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_posting_rules_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_posting_rules_on_workflow_status"
  end

  create_table "price_list_items", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "price_list_id", null: false
    t.uuid "product_id"
    t.uuid "service_id"
    t.integer "min_quantity", default: 1, null: false
    t.bigint "price_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_price_list_items_on_business_type"
    t.index ["company_id"], name: "index_price_list_items_on_company_id"
    t.index ["discarded_at"], name: "index_price_list_items_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_price_list_items_on_lifecycle_status"
    t.index ["price_list_id", "product_id", "min_quantity"], name: "idx_price_list_items_product", unique: true
    t.index ["price_list_id", "service_id", "min_quantity"], name: "idx_price_list_items_service", unique: true
    t.index ["price_list_id"], name: "index_price_list_items_on_price_list_id"
    t.index ["product_id"], name: "index_price_list_items_on_product_id"
    t.index ["service_id"], name: "index_price_list_items_on_service_id"
    t.index ["workflow_status"], name: "index_price_list_items_on_workflow_status"
  end

  create_table "price_lists", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_group_id"
    t.string "name", null: false
    t.text "description"
    t.integer "currency", default: 840
    t.boolean "is_default", default: false, null: false
    t.date "effective_from"
    t.date "effective_to"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_price_lists_on_business_type"
    t.index ["company_id", "name"], name: "index_price_lists_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_price_lists_on_company_id"
    t.index ["customer_group_id"], name: "index_price_lists_on_customer_group_id"
    t.index ["discarded_at"], name: "index_price_lists_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_price_lists_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_price_lists_on_workflow_status"
  end

  create_table "product_barcodes", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.string "barcode", null: false
    t.integer "pack_quantity", default: 1, null: false
    t.boolean "is_primary", default: false, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_barcodes_on_business_type"
    t.index ["company_id", "barcode"], name: "index_product_barcodes_on_company_id_and_barcode", unique: true
    t.index ["company_id"], name: "index_product_barcodes_on_company_id"
    t.index ["discarded_at"], name: "index_product_barcodes_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_product_barcodes_on_lifecycle_status"
    t.index ["product_id", "is_primary"], name: "index_product_barcodes_on_product_id_and_is_primary"
    t.index ["product_id"], name: "index_product_barcodes_on_product_id"
    t.index ["workflow_status"], name: "index_product_barcodes_on_workflow_status"
  end

  create_table "product_bundle_components", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_bundle_id", null: false
    t.uuid "component_product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "is_optional", default: false, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_bundle_components_on_business_type"
    t.index ["company_id"], name: "index_product_bundle_components_on_company_id"
    t.index ["component_product_id"], name: "index_product_bundle_components_on_component_product_id"
    t.index ["discarded_at"], name: "index_product_bundle_components_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_product_bundle_components_on_lifecycle_status"
    t.index ["product_bundle_id", "component_product_id"], name: "idx_bundle_components_unique", unique: true
    t.index ["product_bundle_id"], name: "index_product_bundle_components_on_product_bundle_id"
    t.index ["workflow_status"], name: "index_product_bundle_components_on_workflow_status"
  end

  create_table "product_bundles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.string "name"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_bundles_on_business_type"
    t.index ["company_id", "product_id"], name: "index_product_bundles_on_company_id_and_product_id", unique: true
    t.index ["company_id"], name: "index_product_bundles_on_company_id"
    t.index ["discarded_at"], name: "index_product_bundles_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_product_bundles_on_lifecycle_status"
    t.index ["product_id"], name: "index_product_bundles_on_product_id"
    t.index ["workflow_status"], name: "index_product_bundles_on_workflow_status"
  end

  create_table "product_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_group_tag_appointments_on_business_type"
    t.index ["company_id", "product_group_id", "tag_id"], name: "idx_product_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_product_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_product_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_product_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_product_group_tag_appointments_on_lifecycle_status"
    t.index ["product_group_id"], name: "index_product_group_tag_appointments_on_product_group_id"
    t.index ["tag_id"], name: "index_product_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_product_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_product_groups_on_branch_id"
    t.index ["business_type"], name: "index_product_groups_on_business_type"
    t.index ["category_id"], name: "index_product_groups_on_category_id"
    t.index ["code"], name: "index_product_groups_on_code", unique: true
    t.index ["company_id"], name: "index_product_groups_on_company_id"
    t.index ["discarded_at"], name: "index_product_groups_on_discarded_at"
    t.index ["email"], name: "index_product_groups_on_email", unique: true
    t.index ["external_id"], name: "index_product_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_product_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_product_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_product_groups_on_workflow_status"
  end

  create_table "product_product_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.uuid "product_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_product_group_appointments_on_business_type"
    t.index ["company_id", "product_id", "product_group_id"], name: "idx_product_product_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_product_product_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_product_product_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_product_product_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_product_product_group_appointments_on_lifecycle_status"
    t.index ["product_group_id"], name: "index_product_product_group_appointments_on_product_group_id"
    t.index ["product_id"], name: "index_product_product_group_appointments_on_product_id"
    t.index ["workflow_status"], name: "index_product_product_group_appointments_on_workflow_status"
  end

  create_table "product_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_product_tag_appointments_on_business_type"
    t.index ["company_id", "product_id", "tag_id"], name: "idx_product_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_product_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_product_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_product_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_product_tag_appointments_on_lifecycle_status"
    t.index ["product_id"], name: "index_product_tag_appointments_on_product_id"
    t.index ["tag_id"], name: "index_product_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_product_tag_appointments_on_workflow_status"
  end

  create_table "production_operations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "production_routing_id", null: false
    t.uuid "work_center_id"
    t.integer "position", default: 1, null: false
    t.string "name", null: false
    t.integer "setup_minutes", default: 0, null: false
    t.decimal "run_minutes_per_unit", precision: 15, scale: 4, default: "0.0", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_production_operations_on_business_type"
    t.index ["company_id"], name: "index_production_operations_on_company_id"
    t.index ["discarded_at"], name: "index_production_operations_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_production_operations_on_lifecycle_status"
    t.index ["production_routing_id", "position"], name: "idx_on_production_routing_id_position_efdbbbf151", unique: true
    t.index ["production_routing_id"], name: "index_production_operations_on_production_routing_id"
    t.index ["work_center_id"], name: "index_production_operations_on_work_center_id"
    t.index ["workflow_status"], name: "index_production_operations_on_workflow_status"
  end

  create_table "production_order_materials", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "production_order_id", null: false
    t.uuid "product_id", null: false
    t.uuid "stock_lot_id"
    t.decimal "required_quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.decimal "consumed_quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_production_order_materials_on_business_type"
    t.index ["company_id"], name: "index_production_order_materials_on_company_id"
    t.index ["discarded_at"], name: "index_production_order_materials_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_production_order_materials_on_lifecycle_status"
    t.index ["product_id"], name: "index_production_order_materials_on_product_id"
    t.index ["production_order_id", "product_id"], name: "idx_production_order_materials_unique", unique: true
    t.index ["production_order_id"], name: "index_production_order_materials_on_production_order_id"
    t.index ["stock_lot_id"], name: "index_production_order_materials_on_stock_lot_id"
    t.index ["workflow_status"], name: "index_production_order_materials_on_workflow_status"
  end

  create_table "production_order_operations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "production_order_id", null: false
    t.uuid "production_operation_id", null: false
    t.uuid "work_center_id"
    t.uuid "employee_id"
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "logged_minutes", default: 0, null: false
    t.decimal "produced_quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_production_order_operations_on_business_type"
    t.index ["company_id"], name: "index_production_order_operations_on_company_id"
    t.index ["discarded_at"], name: "index_production_order_operations_on_discarded_at"
    t.index ["employee_id"], name: "index_production_order_operations_on_employee_id"
    t.index ["lifecycle_status"], name: "index_production_order_operations_on_lifecycle_status"
    t.index ["production_operation_id"], name: "index_production_order_operations_on_production_operation_id"
    t.index ["production_order_id", "production_operation_id"], name: "idx_production_order_operations_unique", unique: true
    t.index ["production_order_id"], name: "index_production_order_operations_on_production_order_id"
    t.index ["work_center_id", "status"], name: "index_production_order_operations_on_work_center_id_and_status"
    t.index ["work_center_id"], name: "index_production_order_operations_on_work_center_id"
    t.index ["workflow_status"], name: "index_production_order_operations_on_workflow_status"
  end

  create_table "production_orders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.uuid "bill_of_material_id"
    t.uuid "warehouse_id", null: false
    t.string "code"
    t.decimal "quantity", precision: 15, scale: 4, default: "1.0", null: false
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 1, null: false
    t.datetime "scheduled_start_at"
    t.datetime "scheduled_end_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_of_material_id"], name: "index_production_orders_on_bill_of_material_id"
    t.index ["business_type"], name: "index_production_orders_on_business_type"
    t.index ["company_id", "scheduled_start_at"], name: "index_production_orders_on_company_id_and_scheduled_start_at"
    t.index ["company_id", "status"], name: "index_production_orders_on_company_id_and_status"
    t.index ["company_id"], name: "index_production_orders_on_company_id"
    t.index ["discarded_at"], name: "index_production_orders_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_production_orders_on_lifecycle_status"
    t.index ["product_id"], name: "index_production_orders_on_product_id"
    t.index ["warehouse_id"], name: "index_production_orders_on_warehouse_id"
    t.index ["workflow_status"], name: "index_production_orders_on_workflow_status"
  end

  create_table "production_routings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "bill_of_material_id", null: false
    t.string "name"
    t.string "version", default: "1", null: false
    t.integer "status", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_of_material_id"], name: "index_production_routings_on_bill_of_material_id"
    t.index ["business_type"], name: "index_production_routings_on_business_type"
    t.index ["company_id", "bill_of_material_id", "version"], name: "idx_routing_version_unique", unique: true
    t.index ["company_id"], name: "index_production_routings_on_company_id"
    t.index ["discarded_at"], name: "index_production_routings_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_production_routings_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_production_routings_on_workflow_status"
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
    t.string "external_id"
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
    t.uuid "tax_code_id"
    t.uuid "default_supplier_id"
    t.bigint "cost_cents", default: 0, null: false
    t.boolean "is_kit", default: false, null: false
    t.boolean "track_lot", default: false, null: false
    t.boolean "track_serial", default: false, null: false
    t.string "unit_of_measure"
    t.string "commodity_code"
    t.integer "weight_grams", default: 0, null: false
    t.integer "volume_cm3", default: 0, null: false
    t.index ["branch_id"], name: "index_products_on_branch_id"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["business_type"], name: "index_products_on_business_type"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["code"], name: "index_products_on_code", unique: true
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["default_supplier_id"], name: "index_products_on_default_supplier_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["email"], name: "index_products_on_email", unique: true
    t.index ["external_id"], name: "index_products_on_external_id"
    t.index ["lifecycle_status"], name: "index_products_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_products_on_property_mapping_id"
    t.index ["tax_code_id"], name: "index_products_on_tax_code_id"
    t.index ["workflow_status"], name: "index_products_on_workflow_status"
  end

  create_table "project_billing_terms", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_id", null: false
    t.integer "billing_model", default: 2, null: false
    t.bigint "rate_cents", default: 0, null: false
    t.bigint "cap_cents"
    t.integer "currency", default: 840
    t.integer "retainer_period_days"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_project_billing_terms_on_business_type"
    t.index ["company_id", "project_id"], name: "index_project_billing_terms_on_company_id_and_project_id", unique: true
    t.index ["company_id"], name: "index_project_billing_terms_on_company_id"
    t.index ["discarded_at"], name: "index_project_billing_terms_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_project_billing_terms_on_lifecycle_status"
    t.index ["project_id"], name: "index_project_billing_terms_on_project_id"
    t.index ["workflow_status"], name: "index_project_billing_terms_on_workflow_status"
  end

  create_table "project_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_project_group_tag_appointments_on_business_type"
    t.index ["company_id", "project_group_id", "tag_id"], name: "idx_project_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_project_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_project_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_project_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_project_group_tag_appointments_on_lifecycle_status"
    t.index ["project_group_id"], name: "index_project_group_tag_appointments_on_project_group_id"
    t.index ["tag_id"], name: "index_project_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_project_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_project_groups_on_branch_id"
    t.index ["business_type"], name: "index_project_groups_on_business_type"
    t.index ["category_id"], name: "index_project_groups_on_category_id"
    t.index ["code"], name: "index_project_groups_on_code", unique: true
    t.index ["company_id"], name: "index_project_groups_on_company_id"
    t.index ["discarded_at"], name: "index_project_groups_on_discarded_at"
    t.index ["email"], name: "index_project_groups_on_email", unique: true
    t.index ["external_id"], name: "index_project_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_project_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_project_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_project_groups_on_workflow_status"
  end

  create_table "project_milestones", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_id", null: false
    t.uuid "invoice_id"
    t.string "name", null: false
    t.text "description"
    t.bigint "amount_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.date "due_on"
    t.integer "status", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_project_milestones_on_business_type"
    t.index ["company_id", "project_id", "due_on"], name: "idx_on_company_id_project_id_due_on_8bdb02d4ba"
    t.index ["company_id"], name: "index_project_milestones_on_company_id"
    t.index ["discarded_at"], name: "index_project_milestones_on_discarded_at"
    t.index ["invoice_id"], name: "index_project_milestones_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_project_milestones_on_lifecycle_status"
    t.index ["project_id"], name: "index_project_milestones_on_project_id"
    t.index ["workflow_status"], name: "index_project_milestones_on_workflow_status"
  end

  create_table "project_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_project_tag_appointments_on_business_type"
    t.index ["company_id", "project_id", "tag_id"], name: "idx_project_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_project_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_project_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_project_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_project_tag_appointments_on_lifecycle_status"
    t.index ["project_id"], name: "index_project_tag_appointments_on_project_id"
    t.index ["tag_id"], name: "index_project_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_project_tag_appointments_on_workflow_status"
  end

  create_table "project_time_entries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "project_id", null: false
    t.uuid "task_id"
    t.uuid "employee_id", null: false
    t.uuid "invoice_id"
    t.date "worked_on", null: false
    t.integer "minutes", default: 0, null: false
    t.boolean "billable", default: true, null: false
    t.bigint "rate_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_project_time_entries_on_business_type"
    t.index ["company_id", "project_id", "worked_on"], name: "idx_on_company_id_project_id_worked_on_5fa15a5dcd"
    t.index ["company_id"], name: "index_project_time_entries_on_company_id"
    t.index ["discarded_at"], name: "index_project_time_entries_on_discarded_at"
    t.index ["employee_id", "worked_on"], name: "index_project_time_entries_on_employee_id_and_worked_on"
    t.index ["employee_id"], name: "index_project_time_entries_on_employee_id"
    t.index ["invoice_id"], name: "index_project_time_entries_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_project_time_entries_on_lifecycle_status"
    t.index ["project_id"], name: "index_project_time_entries_on_project_id"
    t.index ["task_id"], name: "index_project_time_entries_on_task_id"
    t.index ["workflow_status"], name: "index_project_time_entries_on_workflow_status"
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
    t.string "external_id"
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
    t.uuid "customer_id"
    t.uuid "manager_employee_id"
    t.uuid "cost_center_id"
    t.integer "billing_model", default: 2, null: false
    t.bigint "budget_cents", default: 0, null: false
    t.date "planned_start_on"
    t.date "planned_end_on"
    t.date "actual_start_on"
    t.date "actual_end_on"
    t.integer "progress_percent", default: 0, null: false
    t.index ["branch_id"], name: "index_projects_on_branch_id"
    t.index ["business_type"], name: "index_projects_on_business_type"
    t.index ["category_id"], name: "index_projects_on_category_id"
    t.index ["code"], name: "index_projects_on_code", unique: true
    t.index ["company_id"], name: "index_projects_on_company_id"
    t.index ["cost_center_id"], name: "index_projects_on_cost_center_id"
    t.index ["customer_id"], name: "index_projects_on_customer_id"
    t.index ["discarded_at"], name: "index_projects_on_discarded_at"
    t.index ["email"], name: "index_projects_on_email", unique: true
    t.index ["external_id"], name: "index_projects_on_external_id"
    t.index ["lifecycle_status"], name: "index_projects_on_lifecycle_status"
    t.index ["manager_employee_id"], name: "index_projects_on_manager_employee_id"
    t.index ["project_group_id"], name: "index_projects_on_project_group_id"
    t.index ["property_mapping_id"], name: "index_projects_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_projects_on_workflow_status"
  end

  create_table "promo_campaigns", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "title", null: false
    t.text "body", null: false
    t.bigint "amount", null: false
    t.bigint "max_cap", null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "processed_at"
    t.jsonb "stats", default: {}, null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_promo_campaigns_on_business_type"
    t.index ["discarded_at"], name: "index_promo_campaigns_on_discarded_at"
    t.index ["external_id"], name: "index_promo_campaigns_on_external_id"
    t.index ["lifecycle_status"], name: "index_promo_campaigns_on_lifecycle_status"
    t.index ["scheduled_at"], name: "index_promo_campaigns_on_scheduled_at"
    t.index ["status"], name: "index_promo_campaigns_on_status"
    t.index ["workflow_status"], name: "index_promo_campaigns_on_workflow_status"
  end

  create_table "promo_grants", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "promo_campaign_id", null: false
    t.uuid "company_id", null: false
    t.bigint "granted_amount", null: false
    t.bigint "promo_before", null: false
    t.bigint "promo_after", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_promo_grants_on_business_type"
    t.index ["company_id"], name: "index_promo_grants_on_company_id"
    t.index ["discarded_at"], name: "index_promo_grants_on_discarded_at"
    t.index ["external_id"], name: "index_promo_grants_on_external_id"
    t.index ["lifecycle_status"], name: "index_promo_grants_on_lifecycle_status"
    t.index ["promo_campaign_id", "company_id"], name: "index_promo_grants_on_promo_campaign_id_and_company_id", unique: true
    t.index ["promo_campaign_id"], name: "index_promo_grants_on_promo_campaign_id"
    t.index ["workflow_status"], name: "index_promo_grants_on_workflow_status"
  end

  create_table "property_mappings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_property_mappings_on_external_id"
    t.index ["lifecycle_status"], name: "index_property_mappings_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_property_mappings_on_workflow_status"
  end

  create_table "purchase_item_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "purchase_item_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_purchase_item_tag_appointments_on_business_type"
    t.index ["company_id", "purchase_item_id", "tag_id"], name: "idx_purchase_item_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_purchase_item_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_item_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_purchase_item_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_purchase_item_tag_appointments_on_lifecycle_status"
    t.index ["purchase_item_id"], name: "index_purchase_item_tag_appointments_on_purchase_item_id"
    t.index ["tag_id"], name: "index_purchase_item_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_purchase_item_tag_appointments_on_workflow_status"
  end

  create_table "purchase_items", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "unit"
    t.decimal "estimated_unit_price"
    t.string "external_id"
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
    t.index ["business_type"], name: "index_purchase_items_on_business_type"
    t.index ["category_id"], name: "index_purchase_items_on_category_id"
    t.index ["code"], name: "index_purchase_items_on_code", unique: true
    t.index ["company_id"], name: "index_purchase_items_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_items_on_discarded_at"
    t.index ["external_id"], name: "index_purchase_items_on_external_id"
    t.index ["lifecycle_status"], name: "index_purchase_items_on_lifecycle_status"
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["property_mapping_id"], name: "index_purchase_items_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_purchase_items_on_workflow_status"
  end

  create_table "purchase_match_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "purchase_id", null: false
    t.uuid "related_purchase_id"
    t.uuid "stock_import_id"
    t.integer "matched_quantity", default: 0, null: false
    t.bigint "matched_amount_cents", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_purchase_match_appointments_on_business_type"
    t.index ["company_id", "status"], name: "index_purchase_match_appointments_on_company_id_and_status"
    t.index ["company_id"], name: "index_purchase_match_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_match_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_purchase_match_appointments_on_lifecycle_status"
    t.index ["purchase_id"], name: "index_purchase_match_appointments_on_purchase_id"
    t.index ["related_purchase_id"], name: "index_purchase_match_appointments_on_related_purchase_id"
    t.index ["stock_import_id"], name: "index_purchase_match_appointments_on_stock_import_id"
    t.index ["workflow_status"], name: "index_purchase_match_appointments_on_workflow_status"
  end

  create_table "purchase_parent_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "purchase_id", null: false
    t.uuid "related_purchase_id", null: false
    t.integer "link_type", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_purchase_parent_appointments_on_business_type"
    t.index ["company_id"], name: "index_purchase_parent_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_parent_appointments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_purchase_parent_appointments_on_lifecycle_status"
    t.index ["purchase_id", "related_purchase_id", "link_type"], name: "idx_purchase_parent_unique", unique: true
    t.index ["purchase_id"], name: "index_purchase_parent_appointments_on_purchase_id"
    t.index ["related_purchase_id"], name: "index_purchase_parent_appointments_on_related_purchase_id"
    t.index ["workflow_status"], name: "index_purchase_parent_appointments_on_workflow_status"
  end

  create_table "purchase_purchase_item_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "purchase_id", null: false
    t.uuid "purchase_item_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "total_price"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_purchase_purchase_item_appointments_on_business_type"
    t.index ["company_id", "purchase_id", "purchase_item_id"], name: "idx_purchase_purchase_item_appointments_triple"
    t.index ["company_id"], name: "index_purchase_purchase_item_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_purchase_item_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_purchase_purchase_item_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_purchase_purchase_item_appointments_on_lifecycle_status"
    t.index ["purchase_id"], name: "index_purchase_purchase_item_appointments_on_purchase_id"
    t.index ["purchase_item_id"], name: "index_purchase_purchase_item_appointments_on_purchase_item_id"
    t.index ["workflow_status"], name: "index_purchase_purchase_item_appointments_on_workflow_status"
  end

  create_table "purchase_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "purchase_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_purchase_tag_appointments_on_business_type"
    t.index ["company_id", "purchase_id", "tag_id"], name: "idx_purchase_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_purchase_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_purchase_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_purchase_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_purchase_tag_appointments_on_lifecycle_status"
    t.index ["purchase_id"], name: "index_purchase_tag_appointments_on_purchase_id"
    t.index ["tag_id"], name: "index_purchase_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_purchase_tag_appointments_on_workflow_status"
  end

  create_table "purchases", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "supplier_id"
    t.uuid "warehouse_id", null: false
    t.uuid "workflow_step_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.datetime "needed_by"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.string "external_id"
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
    t.uuid "payment_term_id"
    t.integer "document_type", default: 2, null: false
    t.bigint "total_cents", default: 0, null: false
    t.decimal "currency_rate", precision: 18, scale: 10, default: "1.0"
    t.datetime "converted_at"
    t.datetime "approved_at"
    t.datetime "received_at"
    t.datetime "billed_at"
    t.index ["branch_id"], name: "index_purchases_on_branch_id"
    t.index ["business_type"], name: "index_purchases_on_business_type"
    t.index ["category_id"], name: "index_purchases_on_category_id"
    t.index ["code"], name: "index_purchases_on_code", unique: true
    t.index ["company_id", "document_type"], name: "index_purchases_on_company_id_and_document_type"
    t.index ["company_id"], name: "index_purchases_on_company_id"
    t.index ["discarded_at"], name: "index_purchases_on_discarded_at"
    t.index ["external_id"], name: "index_purchases_on_external_id"
    t.index ["lifecycle_status"], name: "index_purchases_on_lifecycle_status"
    t.index ["payment_term_id"], name: "index_purchases_on_payment_term_id"
    t.index ["property_mapping_id"], name: "index_purchases_on_property_mapping_id"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchases_on_warehouse_id"
    t.index ["workflow_status"], name: "index_purchases_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_purchases_on_workflow_step_id"
  end

  create_table "quality_checks", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "quality_inspection_id", null: false
    t.string "name", null: false
    t.string "characteristic"
    t.decimal "min_value", precision: 15, scale: 4
    t.decimal "max_value", precision: 15, scale: 4
    t.decimal "measured_value", precision: 15, scale: 4
    t.integer "result", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_quality_checks_on_business_type"
    t.index ["company_id"], name: "index_quality_checks_on_company_id"
    t.index ["discarded_at"], name: "index_quality_checks_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_quality_checks_on_lifecycle_status"
    t.index ["quality_inspection_id", "name"], name: "index_quality_checks_on_quality_inspection_id_and_name"
    t.index ["quality_inspection_id"], name: "index_quality_checks_on_quality_inspection_id"
    t.index ["workflow_status"], name: "index_quality_checks_on_workflow_status"
  end

  create_table "quality_inspections", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "inspector_employee_id"
    t.integer "inspection_type", default: 0, null: false
    t.string "subject_type", null: false
    t.uuid "subject_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "inspected_at"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_quality_inspections_on_business_type"
    t.index ["company_id", "status"], name: "index_quality_inspections_on_company_id_and_status"
    t.index ["company_id"], name: "index_quality_inspections_on_company_id"
    t.index ["discarded_at"], name: "index_quality_inspections_on_discarded_at"
    t.index ["inspector_employee_id"], name: "index_quality_inspections_on_inspector_employee_id"
    t.index ["lifecycle_status"], name: "index_quality_inspections_on_lifecycle_status"
    t.index ["subject_type", "subject_id"], name: "idx_quality_inspections_subject"
    t.index ["workflow_status"], name: "index_quality_inspections_on_workflow_status"
  end

  create_table "question_options", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "question_id", null: false
    t.string "content", null: false
    t.boolean "correct", default: false, null: false
    t.integer "position", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_question_options_on_company_id"
    t.index ["discarded_at"], name: "index_question_options_on_discarded_at"
    t.index ["question_id", "position"], name: "index_question_options_on_question_id_and_position"
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "question_type", default: 0, null: false
    t.integer "points", default: 1, null: false
    t.text "correct_text"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["company_id", "category_id"], name: "index_questions_on_company_id_and_category_id"
    t.index ["company_id", "name"], name: "index_questions_on_company_id_and_name"
    t.index ["company_id", "question_type"], name: "index_questions_on_company_id_and_question_type"
    t.index ["company_id"], name: "index_questions_on_company_id"
    t.index ["discarded_at"], name: "index_questions_on_discarded_at"
  end

  create_table "record_comments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.string "subject_type", null: false
    t.uuid "subject_id", null: false
    t.text "body_markdown", null: false
    t.datetime "edited_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_record_comments_on_business_type"
    t.index ["company_id", "created_at"], name: "index_record_comments_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_record_comments_on_company_id"
    t.index ["discarded_at"], name: "index_record_comments_on_discarded_at"
    t.index ["employee_id"], name: "index_record_comments_on_employee_id"
    t.index ["lifecycle_status"], name: "index_record_comments_on_lifecycle_status"
    t.index ["subject_type", "subject_id", "created_at"], name: "idx_record_comments_subject"
    t.index ["workflow_status"], name: "index_record_comments_on_workflow_status"
  end

  create_table "refunds", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "customer_id"
    t.uuid "order_id"
    t.uuid "invoice_id"
    t.uuid "transaction_id"
    t.uuid "payment_method_id"
    t.uuid "product_id"
    t.uuid "workflow_step_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.integer "refund_type", default: 0, null: false
    t.text "reason"
    t.integer "money_amount_cents"
    t.integer "currency"
    t.integer "quantity"
    t.integer "country"
    t.integer "timezone"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.string "property_string_1"
    t.string "property_string_2"
    t.string "property_string_3"
    t.string "property_string_4"
    t.string "property_string_5"
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
    t.index ["branch_id"], name: "index_refunds_on_branch_id"
    t.index ["category_id"], name: "index_refunds_on_category_id"
    t.index ["code"], name: "index_refunds_on_code", unique: true
    t.index ["company_id"], name: "index_refunds_on_company_id"
    t.index ["customer_id"], name: "index_refunds_on_customer_id"
    t.index ["discarded_at"], name: "index_refunds_on_discarded_at"
    t.index ["external_id"], name: "index_refunds_on_external_id"
    t.index ["invoice_id"], name: "index_refunds_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_refunds_on_lifecycle_status"
    t.index ["order_id"], name: "index_refunds_on_order_id"
    t.index ["payment_method_id"], name: "index_refunds_on_payment_method_id"
    t.index ["product_id"], name: "index_refunds_on_product_id"
    t.index ["property_mapping_id"], name: "index_refunds_on_property_mapping_id"
    t.index ["refund_type"], name: "index_refunds_on_refund_type"
    t.index ["transaction_id"], name: "index_refunds_on_transaction_id"
    t.index ["workflow_status"], name: "index_refunds_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_refunds_on_workflow_step_id"
  end

  create_table "reorder_rules", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.uuid "warehouse_id", null: false
    t.integer "min_quantity", default: 0, null: false
    t.integer "max_quantity", default: 0, null: false
    t.integer "safety_stock", default: 0, null: false
    t.integer "lead_time_days", default: 0, null: false
    t.integer "auto_action", default: 2, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_reorder_rules_on_business_type"
    t.index ["company_id"], name: "index_reorder_rules_on_company_id"
    t.index ["discarded_at"], name: "index_reorder_rules_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_reorder_rules_on_lifecycle_status"
    t.index ["product_id", "warehouse_id"], name: "index_reorder_rules_on_product_id_and_warehouse_id", unique: true
    t.index ["product_id"], name: "index_reorder_rules_on_product_id"
    t.index ["warehouse_id"], name: "index_reorder_rules_on_warehouse_id"
    t.index ["workflow_status"], name: "index_reorder_rules_on_workflow_status"
  end

  create_table "role_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "role_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_role_tag_appointments_on_business_type"
    t.index ["company_id", "role_id", "tag_id"], name: "idx_role_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_role_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_role_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_role_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_role_tag_appointments_on_lifecycle_status"
    t.index ["role_id"], name: "index_role_tag_appointments_on_role_id"
    t.index ["tag_id"], name: "index_role_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_role_tag_appointments_on_workflow_status"
  end

  create_table "roles", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.integer "model_type"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_roles_on_external_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_scheduled_shifts_on_external_id"
    t.index ["shift_template_id"], name: "index_scheduled_shifts_on_shift_template_id"
  end

  create_table "service_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_service_group_tag_appointments_on_business_type"
    t.index ["company_id", "service_group_id", "tag_id"], name: "idx_service_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_service_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_service_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_service_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_service_group_tag_appointments_on_lifecycle_status"
    t.index ["service_group_id"], name: "index_service_group_tag_appointments_on_service_group_id"
    t.index ["tag_id"], name: "index_service_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_service_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_service_groups_on_branch_id"
    t.index ["business_type"], name: "index_service_groups_on_business_type"
    t.index ["category_id"], name: "index_service_groups_on_category_id"
    t.index ["code"], name: "index_service_groups_on_code", unique: true
    t.index ["company_id"], name: "index_service_groups_on_company_id"
    t.index ["discarded_at"], name: "index_service_groups_on_discarded_at"
    t.index ["email"], name: "index_service_groups_on_email", unique: true
    t.index ["external_id"], name: "index_service_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_service_groups_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_service_groups_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_service_groups_on_workflow_status"
  end

  create_table "service_service_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_id", null: false
    t.uuid "service_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_service_service_group_appointments_on_business_type"
    t.index ["company_id", "service_id", "service_group_id"], name: "idx_service_service_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_service_service_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_service_service_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_service_service_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_service_service_group_appointments_on_lifecycle_status"
    t.index ["service_group_id"], name: "index_service_service_group_appointments_on_service_group_id"
    t.index ["service_id"], name: "index_service_service_group_appointments_on_service_id"
    t.index ["workflow_status"], name: "index_service_service_group_appointments_on_workflow_status"
  end

  create_table "service_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_service_tag_appointments_on_business_type"
    t.index ["company_id", "service_id", "tag_id"], name: "idx_service_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_service_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_service_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_service_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_service_tag_appointments_on_lifecycle_status"
    t.index ["service_id"], name: "index_service_tag_appointments_on_service_id"
    t.index ["tag_id"], name: "index_service_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_service_tag_appointments_on_workflow_status"
  end

  create_table "service_visit_parts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "service_visit_id", null: false
    t.uuid "product_id", null: false
    t.uuid "stock_id"
    t.integer "quantity", default: 1, null: false
    t.bigint "price_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_service_visit_parts_on_business_type"
    t.index ["company_id"], name: "index_service_visit_parts_on_company_id"
    t.index ["discarded_at"], name: "index_service_visit_parts_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_service_visit_parts_on_lifecycle_status"
    t.index ["product_id"], name: "index_service_visit_parts_on_product_id"
    t.index ["service_visit_id", "product_id"], name: "index_service_visit_parts_on_service_visit_id_and_product_id"
    t.index ["service_visit_id"], name: "index_service_visit_parts_on_service_visit_id"
    t.index ["stock_id"], name: "index_service_visit_parts_on_stock_id"
    t.index ["workflow_status"], name: "index_service_visit_parts_on_workflow_status"
  end

  create_table "service_visits", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "customer_id", null: false
    t.uuid "project_id"
    t.uuid "facility_id"
    t.uuid "assigned_employee_id"
    t.datetime "scheduled_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "status", default: 0, null: false
    t.text "report"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_employee_id", "status"], name: "index_service_visits_on_assigned_employee_id_and_status"
    t.index ["assigned_employee_id"], name: "index_service_visits_on_assigned_employee_id"
    t.index ["business_type"], name: "index_service_visits_on_business_type"
    t.index ["company_id", "scheduled_at"], name: "index_service_visits_on_company_id_and_scheduled_at"
    t.index ["company_id"], name: "index_service_visits_on_company_id"
    t.index ["customer_id"], name: "index_service_visits_on_customer_id"
    t.index ["discarded_at"], name: "index_service_visits_on_discarded_at"
    t.index ["facility_id"], name: "index_service_visits_on_facility_id"
    t.index ["lifecycle_status"], name: "index_service_visits_on_lifecycle_status"
    t.index ["project_id"], name: "index_service_visits_on_project_id"
    t.index ["workflow_status"], name: "index_service_visits_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_services_on_branch_id"
    t.index ["business_type"], name: "index_services_on_business_type"
    t.index ["category_id"], name: "index_services_on_category_id"
    t.index ["code"], name: "index_services_on_code", unique: true
    t.index ["company_id"], name: "index_services_on_company_id"
    t.index ["discarded_at"], name: "index_services_on_discarded_at"
    t.index ["email"], name: "index_services_on_email", unique: true
    t.index ["external_id"], name: "index_services_on_external_id"
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
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_sessions_on_external_id"
    t.index ["single_access_token"], name: "index_sessions_on_single_access_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_shift_templates_on_external_id"
  end

  create_table "sign_in_tokens", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "external_id"
    t.index ["external_id"], name: "index_sign_in_tokens_on_external_id"
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "signature_events", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "signature_request_id", null: false
    t.string "signer_email", null: false
    t.string "signer_name"
    t.datetime "signed_at"
    t.string "ip_address"
    t.string "signature_hash"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_signature_events_on_company_id"
    t.index ["signature_request_id", "signed_at"], name: "index_signature_events_on_signature_request_id_and_signed_at"
    t.index ["signature_request_id"], name: "index_signature_events_on_signature_request_id"
  end

  create_table "signature_requests", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "document_id"
    t.uuid "stored_file_id"
    t.uuid "requested_by_employee_id"
    t.integer "status", default: 0, null: false
    t.text "message"
    t.datetime "expires_at"
    t.datetime "completed_at"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_signature_requests_on_business_type"
    t.index ["company_id", "status"], name: "index_signature_requests_on_company_id_and_status"
    t.index ["company_id"], name: "index_signature_requests_on_company_id"
    t.index ["discarded_at"], name: "index_signature_requests_on_discarded_at"
    t.index ["document_id"], name: "index_signature_requests_on_document_id"
    t.index ["lifecycle_status"], name: "index_signature_requests_on_lifecycle_status"
    t.index ["requested_by_employee_id"], name: "index_signature_requests_on_requested_by_employee_id"
    t.index ["stored_file_id"], name: "index_signature_requests_on_stored_file_id"
    t.index ["workflow_status"], name: "index_signature_requests_on_workflow_status"
  end

  create_table "statistic_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "statistic_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_statistic_tag_appointments_on_business_type"
    t.index ["company_id", "statistic_id", "tag_id"], name: "idx_statistic_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_statistic_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_statistic_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_statistic_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_statistic_tag_appointments_on_lifecycle_status"
    t.index ["statistic_id"], name: "index_statistic_tag_appointments_on_statistic_id"
    t.index ["tag_id"], name: "index_statistic_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_statistic_tag_appointments_on_workflow_status"
  end

  create_table "statistics", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.json "data"
    t.datetime "recorded_at"
    t.jsonb "metadata"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_statistics_on_external_id"
    t.index ["owner_type", "owner_id"], name: "index_statistics_on_owner"
    t.index ["recorded_at"], name: "index_statistics_on_recorded_at"
  end

  create_table "stock_adjustment_stock_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_adjustment_id", null: false
    t.uuid "stock_id", null: false
    t.integer "quantity", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_adjustment_stock_appointments_on_business_type"
    t.index ["company_id", "stock_adjustment_id", "stock_id"], name: "idx_adjustment_stock_triple"
    t.index ["company_id"], name: "index_stock_adjustment_stock_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_adjustment_stock_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_adjustment_stock_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_adjustment_stock_appointments_on_lifecycle_status"
    t.index ["stock_adjustment_id"], name: "idx_on_stock_adjustment_id_bc65c15a3f"
    t.index ["stock_id"], name: "index_stock_adjustment_stock_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_stock_adjustment_stock_appointments_on_workflow_status"
  end

  create_table "stock_adjustments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id", null: false
    t.string "email"
    t.string "name"
    t.text "description"
    t.string "code"
    t.string "phone_number"
    t.string "reason"
    t.integer "direction", null: false
    t.integer "currency", default: 0
    t.integer "country", default: 0
    t.integer "timezone", default: 0
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_stock_adjustments_on_branch_id"
    t.index ["business_type"], name: "index_stock_adjustments_on_business_type"
    t.index ["category_id"], name: "index_stock_adjustments_on_category_id"
    t.index ["code"], name: "index_stock_adjustments_on_code"
    t.index ["company_id", "workflow_status"], name: "index_stock_adjustments_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_stock_adjustments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_adjustments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_adjustments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_adjustments_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_stock_adjustments_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stock_adjustments_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_adjustments_on_workflow_status"
  end

  create_table "stock_count_lines", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_count_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "storage_location_id"
    t.integer "expected_quantity", default: 0, null: false
    t.integer "counted_quantity"
    t.integer "variance_quantity", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_count_lines_on_business_type"
    t.index ["company_id"], name: "index_stock_count_lines_on_company_id"
    t.index ["discarded_at"], name: "index_stock_count_lines_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_stock_count_lines_on_lifecycle_status"
    t.index ["stock_count_id", "stock_id"], name: "index_stock_count_lines_on_stock_count_id_and_stock_id", unique: true
    t.index ["stock_count_id"], name: "index_stock_count_lines_on_stock_count_id"
    t.index ["stock_id"], name: "index_stock_count_lines_on_stock_id"
    t.index ["storage_location_id"], name: "index_stock_count_lines_on_storage_location_id"
    t.index ["workflow_status"], name: "index_stock_count_lines_on_workflow_status"
  end

  create_table "stock_counts", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "created_by_employee_id"
    t.integer "count_type", default: 1, null: false
    t.date "scheduled_on"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_counts_on_business_type"
    t.index ["company_id", "scheduled_on"], name: "index_stock_counts_on_company_id_and_scheduled_on"
    t.index ["company_id"], name: "index_stock_counts_on_company_id"
    t.index ["created_by_employee_id"], name: "index_stock_counts_on_created_by_employee_id"
    t.index ["discarded_at"], name: "index_stock_counts_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_stock_counts_on_lifecycle_status"
    t.index ["warehouse_id", "status"], name: "index_stock_counts_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_stock_counts_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_counts_on_workflow_status"
  end

  create_table "stock_export_stock_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_export_id", null: false
    t.uuid "stock_id", null: false
    t.integer "quantity", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_export_stock_appointments_on_business_type"
    t.index ["company_id", "stock_export_id", "stock_id"], name: "idx_export_stock_triple"
    t.index ["company_id"], name: "index_stock_export_stock_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_export_stock_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_export_stock_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_export_stock_appointments_on_lifecycle_status"
    t.index ["stock_export_id"], name: "index_stock_export_stock_appointments_on_stock_export_id"
    t.index ["stock_id"], name: "index_stock_export_stock_appointments_on_stock_id"
    t.index ["workflow_status"], name: "index_stock_export_stock_appointments_on_workflow_status"
  end

  create_table "stock_export_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_export_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_export_tag_appointments_on_business_type"
    t.index ["company_id", "stock_export_id", "tag_id"], name: "idx_stock_export_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_stock_export_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_export_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_export_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_export_tag_appointments_on_lifecycle_status"
    t.index ["stock_export_id"], name: "index_stock_export_tag_appointments_on_stock_export_id"
    t.index ["tag_id"], name: "index_stock_export_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_stock_export_tag_appointments_on_workflow_status"
  end

  create_table "stock_exports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_stock_exports_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_exports_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_exports_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_exports_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stock_exports_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_exports_on_workflow_status"
  end

  create_table "stock_import_stock_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_import_id", null: false
    t.uuid "stock_id", null: false
    t.integer "quantity", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_import_stock_appointments_on_business_type"
    t.index ["company_id", "stock_import_id", "stock_id"], name: "idx_import_stock_triple"
    t.index ["company_id"], name: "index_stock_import_stock_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_import_stock_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_import_stock_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_import_stock_appointments_on_lifecycle_status"
    t.index ["stock_id"], name: "index_stock_import_stock_appointments_on_stock_id"
    t.index ["stock_import_id"], name: "index_stock_import_stock_appointments_on_stock_import_id"
    t.index ["workflow_status"], name: "index_stock_import_stock_appointments_on_workflow_status"
  end

  create_table "stock_import_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_import_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_import_tag_appointments_on_business_type"
    t.index ["company_id", "stock_import_id", "tag_id"], name: "idx_stock_import_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_stock_import_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_import_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_import_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_import_tag_appointments_on_lifecycle_status"
    t.index ["stock_import_id"], name: "index_stock_import_tag_appointments_on_stock_import_id"
    t.index ["tag_id"], name: "index_stock_import_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_stock_import_tag_appointments_on_workflow_status"
  end

  create_table "stock_imports", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "product_id"
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
    t.string "external_id"
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
    t.uuid "purchase_id"
    t.datetime "received_at"
    t.integer "quality_status"
    t.bigint "landed_cost_total_cents", default: 0, null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_stock_imports_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_stock_imports_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_stock_imports_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_stock_imports_on_appoint_to"
    t.index ["branch_id"], name: "index_stock_imports_on_branch_id"
    t.index ["business_type"], name: "index_stock_imports_on_business_type"
    t.index ["category_id"], name: "index_stock_imports_on_category_id"
    t.index ["code"], name: "index_stock_imports_on_code", unique: true
    t.index ["company_id", "received_at"], name: "index_stock_imports_on_company_id_and_received_at"
    t.index ["company_id"], name: "index_stock_imports_on_company_id"
    t.index ["discarded_at"], name: "index_stock_imports_on_discarded_at"
    t.index ["email"], name: "index_stock_imports_on_email", unique: true
    t.index ["external_id"], name: "index_stock_imports_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_imports_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_imports_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_imports_on_property_mapping_id"
    t.index ["purchase_id"], name: "index_stock_imports_on_purchase_id"
    t.index ["warehouse_id"], name: "index_stock_imports_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_imports_on_workflow_status"
  end

  create_table "stock_lots", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "product_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "supplier_id"
    t.string "lot_code", null: false
    t.date "received_on"
    t.date "expires_on"
    t.integer "status", default: 0, null: false
    t.string "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_lots_on_business_type"
    t.index ["company_id", "expires_on"], name: "index_stock_lots_on_company_id_and_expires_on"
    t.index ["company_id", "product_id", "warehouse_id", "lot_code"], name: "idx_stock_lots_unique", unique: true
    t.index ["company_id"], name: "index_stock_lots_on_company_id"
    t.index ["discarded_at"], name: "index_stock_lots_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_stock_lots_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_lots_on_product_id"
    t.index ["supplier_id"], name: "index_stock_lots_on_supplier_id"
    t.index ["warehouse_id"], name: "index_stock_lots_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_lots_on_workflow_status"
  end

  create_table "stock_pendings", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "product_id", null: false
    t.string "name"
    t.text "reason"
    t.string "code"
    t.integer "quantity", null: false
    t.datetime "status_changed_at"
    t.datetime "released_at"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_pendings_on_business_type"
    t.index ["code"], name: "index_stock_pendings_on_code", unique: true
    t.index ["company_id", "workflow_status"], name: "index_stock_pendings_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_stock_pendings_on_company_id"
    t.index ["discarded_at"], name: "index_stock_pendings_on_discarded_at"
    t.index ["external_id"], name: "index_stock_pendings_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_pendings_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_pendings_on_product_id"
    t.index ["stock_id", "workflow_status"], name: "index_stock_pendings_on_stock_id_and_workflow_status"
    t.index ["stock_id"], name: "index_stock_pendings_on_stock_id"
    t.index ["warehouse_id", "workflow_status"], name: "index_stock_pendings_on_warehouse_id_and_workflow_status"
    t.index ["warehouse_id"], name: "index_stock_pendings_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_pendings_on_workflow_status"
  end

  create_table "stock_serials", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "stock_lot_id"
    t.uuid "storage_location_id"
    t.uuid "sold_order_id"
    t.string "serial_number", null: false
    t.integer "status", default: 0, null: false
    t.datetime "received_at"
    t.datetime "sold_at"
    t.date "warranty_until"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_serials_on_business_type"
    t.index ["company_id", "serial_number"], name: "index_stock_serials_on_company_id_and_serial_number", unique: true
    t.index ["company_id", "status"], name: "index_stock_serials_on_company_id_and_status"
    t.index ["company_id"], name: "index_stock_serials_on_company_id"
    t.index ["discarded_at"], name: "index_stock_serials_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_stock_serials_on_lifecycle_status"
    t.index ["sold_order_id"], name: "index_stock_serials_on_sold_order_id"
    t.index ["stock_id"], name: "index_stock_serials_on_stock_id"
    t.index ["stock_lot_id"], name: "index_stock_serials_on_stock_lot_id"
    t.index ["storage_location_id"], name: "index_stock_serials_on_storage_location_id"
    t.index ["workflow_status"], name: "index_stock_serials_on_workflow_status"
  end

  create_table "stock_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_tag_appointments_on_business_type"
    t.index ["company_id", "stock_id", "tag_id"], name: "idx_stock_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_stock_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_tag_appointments_on_lifecycle_status"
    t.index ["stock_id"], name: "index_stock_tag_appointments_on_stock_id"
    t.index ["tag_id"], name: "index_stock_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_stock_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.uuid "stock_lot_id"
    t.uuid "stock_serial_id"
    t.uuid "storage_location_id"
    t.bigint "unit_cost_cents", default: 0, null: false
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
    t.index ["external_id"], name: "index_stock_transactions_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_transactions_on_lifecycle_status"
    t.index ["product_id"], name: "index_stock_transactions_on_product_id"
    t.index ["property_mapping_id"], name: "index_stock_transactions_on_property_mapping_id"
    t.index ["stock_lot_id"], name: "index_stock_transactions_on_stock_lot_id"
    t.index ["stock_serial_id"], name: "index_stock_transactions_on_stock_serial_id"
    t.index ["storage_location_id"], name: "index_stock_transactions_on_storage_location_id"
    t.index ["transaction_type"], name: "index_stock_transactions_on_transaction_type"
    t.index ["warehouse_id"], name: "index_stock_transactions_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stock_transactions_on_workflow_status"
  end

  create_table "stock_transfer_stock_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_transfer_id", null: false
    t.uuid "stock_id", null: false
    t.integer "quantity", null: false
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_transfer_stock_appointments_on_business_type"
    t.index ["company_id", "stock_transfer_id", "stock_id"], name: "idx_transfer_stock_triple"
    t.index ["company_id"], name: "index_stock_transfer_stock_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_transfer_stock_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_transfer_stock_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_transfer_stock_appointments_on_lifecycle_status"
    t.index ["stock_id"], name: "index_stock_transfer_stock_appointments_on_stock_id"
    t.index ["stock_transfer_id"], name: "index_stock_transfer_stock_appointments_on_stock_transfer_id"
    t.index ["workflow_status"], name: "index_stock_transfer_stock_appointments_on_workflow_status"
  end

  create_table "stock_transfer_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "stock_transfer_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_stock_transfer_tag_appointments_on_business_type"
    t.index ["company_id", "stock_transfer_id", "tag_id"], name: "idx_stock_transfer_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_stock_transfer_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_stock_transfer_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_stock_transfer_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_stock_transfer_tag_appointments_on_lifecycle_status"
    t.index ["stock_transfer_id"], name: "index_stock_transfer_tag_appointments_on_stock_transfer_id"
    t.index ["tag_id"], name: "index_stock_transfer_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_stock_transfer_tag_appointments_on_workflow_status"
  end

  create_table "stock_transfers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.uuid "warehouse_id", null: false
    t.uuid "destination_warehouse_id", null: false
    t.uuid "product_id"
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
    t.datetime "initiated_at"
    t.datetime "received_at"
    t.string "external_id"
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
    t.index ["destination_warehouse_id"], name: "index_stock_transfers_on_destination_warehouse_id"
    t.index ["discarded_at"], name: "index_stock_transfers_on_discarded_at"
    t.index ["email"], name: "index_stock_transfers_on_email", unique: true
    t.index ["external_id"], name: "index_stock_transfers_on_external_id"
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
    t.integer "pending", null: false
    t.string "external_id"
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
    t.index ["external_id"], name: "index_stocks_on_external_id"
    t.index ["lifecycle_status"], name: "index_stocks_on_lifecycle_status"
    t.index ["product_id"], name: "index_stocks_on_product_id"
    t.index ["property_mapping_id"], name: "index_stocks_on_property_mapping_id"
    t.index ["warehouse_id"], name: "index_stocks_on_warehouse_id"
    t.index ["workflow_status"], name: "index_stocks_on_workflow_status"
  end

  create_table "storage_locations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "parent_id"
    t.string "code", null: false
    t.string "name"
    t.integer "location_type", default: 3, null: false
    t.integer "pick_sequence", default: 0, null: false
    t.boolean "is_pickable", default: true, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_storage_locations_on_business_type"
    t.index ["company_id"], name: "index_storage_locations_on_company_id"
    t.index ["discarded_at"], name: "index_storage_locations_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_storage_locations_on_lifecycle_status"
    t.index ["parent_id"], name: "index_storage_locations_on_parent_id"
    t.index ["warehouse_id", "code"], name: "index_storage_locations_on_warehouse_id_and_code", unique: true
    t.index ["warehouse_id", "pick_sequence"], name: "index_storage_locations_on_warehouse_id_and_pick_sequence"
    t.index ["warehouse_id"], name: "index_storage_locations_on_warehouse_id"
    t.index ["workflow_status"], name: "index_storage_locations_on_workflow_status"
  end

  create_table "stored_files", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "folder_id", null: false
    t.string "name", null: false
    t.bigint "file_size", default: 0
    t.string "extension"
    t.string "content_type"
    t.string "attachable_type"
    t.uuid "attachable_id"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_stored_file_id"
    t.integer "version_no", default: 1, null: false
    t.string "checksum"
    t.text "ocr_text"
    t.integer "ocr_status"
    t.datetime "indexed_at"
    t.index ["attachable_type", "attachable_id"], name: "index_stored_files_on_attachable_type_and_attachable_id"
    t.index ["company_id", "folder_id"], name: "index_stored_files_on_company_id_and_folder_id"
    t.index ["company_id"], name: "index_stored_files_on_company_id"
    t.index ["discarded_at"], name: "index_stored_files_on_discarded_at"
    t.index ["external_id"], name: "index_stored_files_on_external_id"
    t.index ["folder_id"], name: "index_stored_files_on_folder_id"
    t.index ["parent_stored_file_id"], name: "index_stored_files_on_parent_stored_file_id"
  end

  create_table "subcontract_orders", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "supplier_id", null: false
    t.uuid "purchase_id"
    t.uuid "product_id", null: false
    t.string "code"
    t.decimal "quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.decimal "sent_quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.decimal "received_quantity", precision: 15, scale: 4, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.date "sent_on"
    t.date "due_on"
    t.text "notes"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_subcontract_orders_on_business_type"
    t.index ["company_id", "status"], name: "index_subcontract_orders_on_company_id_and_status"
    t.index ["company_id"], name: "index_subcontract_orders_on_company_id"
    t.index ["discarded_at"], name: "index_subcontract_orders_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_subcontract_orders_on_lifecycle_status"
    t.index ["product_id"], name: "index_subcontract_orders_on_product_id"
    t.index ["purchase_id"], name: "index_subcontract_orders_on_purchase_id"
    t.index ["supplier_id", "due_on"], name: "index_subcontract_orders_on_supplier_id_and_due_on"
    t.index ["supplier_id"], name: "index_subcontract_orders_on_supplier_id"
    t.index ["workflow_status"], name: "index_subcontract_orders_on_workflow_status"
  end

  create_table "subscription_group_subscription_plan_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "subscription_group_id", null: false
    t.uuid "subscription_plan_id", null: false
    t.integer "price_cents"
    t.integer "currency"
    t.integer "country"
    t.integer "timezone"
    t.boolean "auto_renew"
    t.string "name"
    t.string "description"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "idx_on_business_type_c7a9e65b95"
    t.index ["company_id", "subscription_group_id", "subscription_plan_id"], name: "idx_subscription_group_subscription_plan_appointments_triple"
    t.index ["company_id"], name: "idx_on_company_id_3a831c8ac7"
    t.index ["discarded_at"], name: "idx_on_discarded_at_330a11e9e0"
    t.index ["external_id"], name: "index_subscription_group_sub_plan_appts_on_external_id"
    t.index ["lifecycle_status"], name: "idx_on_lifecycle_status_6cee9c1826"
    t.index ["subscription_group_id"], name: "idx_on_subscription_group_id_925c1f4dae"
    t.index ["subscription_plan_id"], name: "idx_on_subscription_plan_id_169e306d7e"
    t.index ["workflow_status"], name: "idx_on_workflow_status_4739b44ecd"
  end

  create_table "subscription_group_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "subscription_group_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_subscription_group_tag_appointments_on_business_type"
    t.index ["company_id", "subscription_group_id", "tag_id"], name: "idx_subscription_group_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_subscription_group_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_subscription_group_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_subscription_group_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_subscription_group_tag_appointments_on_lifecycle_status"
    t.index ["subscription_group_id"], name: "idx_on_subscription_group_id_41f29c4d0e"
    t.index ["tag_id"], name: "index_subscription_group_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_subscription_group_tag_appointments_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_subscription_groups_on_external_id"
    t.index ["lifecycle_status"], name: "index_subscription_groups_on_lifecycle_status"
    t.index ["subscription_group_id"], name: "index_subscription_groups_on_subscription_group_id"
    t.index ["subscription_plan_id"], name: "index_subscription_groups_on_subscription_plan_id"
    t.index ["workflow_status"], name: "index_subscription_groups_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_subscription_plans_on_external_id"
    t.index ["lifecycle_status"], name: "index_subscription_plans_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_subscription_plans_on_workflow_status"
  end

  create_table "supplier_tag_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "supplier_id", null: false
    t.uuid "tag_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_supplier_tag_appointments_on_business_type"
    t.index ["company_id", "supplier_id", "tag_id"], name: "idx_supplier_tag_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_supplier_tag_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_supplier_tag_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_supplier_tag_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_supplier_tag_appointments_on_lifecycle_status"
    t.index ["supplier_id"], name: "index_supplier_tag_appointments_on_supplier_id"
    t.index ["tag_id"], name: "index_supplier_tag_appointments_on_tag_id"
    t.index ["workflow_status"], name: "index_supplier_tag_appointments_on_workflow_status"
  end

  create_table "suppliers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
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
    t.string "external_id"
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
    t.uuid "payment_term_id"
    t.string "tax_id"
    t.integer "lead_time_days", default: 0, null: false
    t.index ["business_type"], name: "index_suppliers_on_business_type"
    t.index ["category_id"], name: "index_suppliers_on_category_id"
    t.index ["code"], name: "index_suppliers_on_code", unique: true
    t.index ["company_id"], name: "index_suppliers_on_company_id"
    t.index ["discarded_at"], name: "index_suppliers_on_discarded_at"
    t.index ["external_id"], name: "index_suppliers_on_external_id"
    t.index ["lifecycle_status"], name: "index_suppliers_on_lifecycle_status"
    t.index ["payment_term_id"], name: "index_suppliers_on_payment_term_id"
    t.index ["property_mapping_id"], name: "index_suppliers_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_suppliers_on_workflow_status"
  end

  create_table "systems", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.string "email"
    t.string "name", null: false
    t.string "code", null: false, comment: "System"
    t.integer "balance_cents", null: false
    t.integer "currency"
    t.integer "country"
    t.boolean "active", null: false
    t.string "external_id"
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
    t.index ["code"], name: "index_systems_on_code", unique: true
    t.index ["company_id"], name: "index_systems_on_company_id"
    t.index ["discarded_at"], name: "index_systems_on_discarded_at"
    t.index ["external_id"], name: "index_systems_on_external_id"
    t.index ["lifecycle_status"], name: "index_systems_on_lifecycle_status"
    t.index ["name"], name: "index_systems_on_name", unique: true
    t.index ["workflow_status"], name: "index_systems_on_workflow_status"
  end

  create_table "table_config_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "table_config_id"
    t.uuid "category_id"
    t.uuid "property_mapping_id"
    t.uuid "employee_id"
    t.integer "action", null: false
    t.string "employee_name"
    t.string "category_name"
    t.string "property_mapping_name"
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_table_config_logs_on_category_id"
    t.index ["company_id", "created_at"], name: "idx_table_config_logs_on_company_time"
    t.index ["company_id", "table_config_id", "created_at"], name: "idx_table_config_logs_on_config_time"
    t.index ["company_id"], name: "index_table_config_logs_on_company_id"
    t.index ["employee_id"], name: "index_table_config_logs_on_employee_id"
    t.index ["external_id"], name: "index_table_config_logs_on_external_id"
    t.index ["property_mapping_id"], name: "index_table_config_logs_on_property_mapping_id"
    t.index ["table_config_id"], name: "index_table_config_logs_on_table_config_id"
  end

  create_table "table_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id"
    t.string "name"
    t.string "description"
    t.string "resource_name"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_table_configs_on_external_id"
    t.index ["lifecycle_status"], name: "index_table_configs_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_table_configs_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_table_configs_on_workflow_status"
  end

  create_table "tag_task_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.uuid "task_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tag_task_appointments_on_business_type"
    t.index ["company_id", "tag_id", "task_id"], name: "idx_tag_task_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_tag_task_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_tag_task_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_tag_task_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_tag_task_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_tag_task_appointments_on_tag_id"
    t.index ["task_id"], name: "index_tag_task_appointments_on_task_id"
    t.index ["workflow_status"], name: "index_tag_task_appointments_on_workflow_status"
  end

  create_table "tag_task_group_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.uuid "task_group_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tag_task_group_appointments_on_business_type"
    t.index ["company_id", "tag_id", "task_group_id"], name: "idx_tag_task_group_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_tag_task_group_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_tag_task_group_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_tag_task_group_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_tag_task_group_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_tag_task_group_appointments_on_tag_id"
    t.index ["task_group_id"], name: "index_tag_task_group_appointments_on_task_group_id"
    t.index ["workflow_status"], name: "index_tag_task_group_appointments_on_workflow_status"
  end

  create_table "tag_transaction_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.uuid "transaction_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tag_transaction_appointments_on_business_type"
    t.index ["company_id", "tag_id", "transaction_id"], name: "idx_tag_transaction_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_tag_transaction_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_tag_transaction_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_tag_transaction_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_tag_transaction_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_tag_transaction_appointments_on_tag_id"
    t.index ["transaction_id"], name: "index_tag_transaction_appointments_on_transaction_id"
    t.index ["workflow_status"], name: "index_tag_transaction_appointments_on_workflow_status"
  end

  create_table "tag_warehouse_appointments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "tag_id", null: false
    t.uuid "warehouse_id", null: false
    t.string "value"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tag_warehouse_appointments_on_business_type"
    t.index ["company_id", "tag_id", "warehouse_id"], name: "idx_tag_warehouse_appointments_uniq", unique: true
    t.index ["company_id"], name: "index_tag_warehouse_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_tag_warehouse_appointments_on_discarded_at"
    t.index ["external_id"], name: "index_tag_warehouse_appointments_on_external_id"
    t.index ["lifecycle_status"], name: "index_tag_warehouse_appointments_on_lifecycle_status"
    t.index ["tag_id"], name: "index_tag_warehouse_appointments_on_tag_id"
    t.index ["warehouse_id"], name: "index_tag_warehouse_appointments_on_warehouse_id"
    t.index ["workflow_status"], name: "index_tag_warehouse_appointments_on_workflow_status"
  end

  create_table "tags", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "key"
    t.string "value"
    t.string "description"
    t.string "code"
    t.string "permission_resource_name"
    t.string "external_id"
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
    t.index ["external_id"], name: "index_tags_on_external_id"
    t.index ["lifecycle_status"], name: "index_tags_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_tags_on_workflow_status"
  end

  create_table "task_dependencies", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "predecessor_task_id", null: false
    t.uuid "successor_task_id", null: false
    t.integer "dependency_type", default: 0, null: false
    t.integer "lag_days", default: 0, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_task_dependencies_on_business_type"
    t.index ["company_id"], name: "index_task_dependencies_on_company_id"
    t.index ["discarded_at"], name: "index_task_dependencies_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_task_dependencies_on_lifecycle_status"
    t.index ["predecessor_task_id", "successor_task_id"], name: "idx_task_dependencies_unique", unique: true
    t.index ["predecessor_task_id"], name: "index_task_dependencies_on_predecessor_task_id"
    t.index ["successor_task_id"], name: "index_task_dependencies_on_successor_task_id"
    t.index ["workflow_status"], name: "index_task_dependencies_on_workflow_status"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_task_groups_on_branch_id"
    t.index ["business_type"], name: "index_task_groups_on_business_type"
    t.index ["category_id"], name: "index_task_groups_on_category_id"
    t.index ["code"], name: "index_task_groups_on_code", unique: true
    t.index ["company_id"], name: "index_task_groups_on_company_id"
    t.index ["discarded_at"], name: "index_task_groups_on_discarded_at"
    t.index ["email"], name: "index_task_groups_on_email", unique: true
    t.index ["external_id"], name: "index_task_groups_on_external_id"
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
    t.string "external_id"
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
    t.uuid "parent_task_id"
    t.uuid "project_milestone_id"
    t.datetime "planned_start_at"
    t.datetime "planned_end_at"
    t.datetime "actual_start_at"
    t.datetime "actual_end_at"
    t.integer "estimated_minutes", default: 0, null: false
    t.integer "actual_minutes", default: 0, null: false
    t.integer "progress_percent", default: 0, null: false
    t.index ["branch_id"], name: "index_tasks_on_branch_id"
    t.index ["business_type"], name: "index_tasks_on_business_type"
    t.index ["category_id"], name: "index_tasks_on_category_id"
    t.index ["code"], name: "index_tasks_on_code", unique: true
    t.index ["company_id", "planned_start_at"], name: "index_tasks_on_company_id_and_planned_start_at"
    t.index ["company_id"], name: "index_tasks_on_company_id"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["email"], name: "index_tasks_on_email", unique: true
    t.index ["external_id"], name: "index_tasks_on_external_id"
    t.index ["lifecycle_status"], name: "index_tasks_on_lifecycle_status"
    t.index ["parent_task_id"], name: "index_tasks_on_parent_task_id"
    t.index ["project_milestone_id"], name: "index_tasks_on_project_milestone_id"
    t.index ["property_mapping_id"], name: "index_tasks_on_property_mapping_id"
    t.index ["task_group_id"], name: "index_tasks_on_task_group_id"
    t.index ["workflow_status"], name: "index_tasks_on_workflow_status"
  end

  create_table "tax_codes", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "ledger_account_id"
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "kind", null: false
    t.integer "rate_bp", default: 0, null: false
    t.string "jurisdiction"
    t.boolean "is_inclusive", default: false, null: false
    t.date "effective_from"
    t.date "effective_to"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_tax_codes_on_business_type"
    t.index ["company_id", "code"], name: "index_tax_codes_on_company_id_and_code", unique: true
    t.index ["company_id"], name: "index_tax_codes_on_company_id"
    t.index ["discarded_at"], name: "index_tax_codes_on_discarded_at"
    t.index ["ledger_account_id"], name: "index_tax_codes_on_ledger_account_id"
    t.index ["lifecycle_status"], name: "index_tax_codes_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_tax_codes_on_workflow_status"
  end

  create_table "tax_configs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_tax_configs_on_company_id", unique: true
  end

  create_table "ticket_comments", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "ticket_id", null: false
    t.uuid "employee_id", null: false
    t.text "message", null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_ticket_comments_on_business_type"
    t.index ["company_id", "ticket_id"], name: "index_ticket_comments_on_company_id_and_ticket_id"
    t.index ["company_id"], name: "index_ticket_comments_on_company_id"
    t.index ["discarded_at"], name: "index_ticket_comments_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_ticket_comments_on_lifecycle_status"
    t.index ["ticket_id"], name: "index_ticket_comments_on_ticket_id"
    t.index ["workflow_status"], name: "index_ticket_comments_on_workflow_status"
  end

  create_table "ticket_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "ticket_id", null: false
    t.string "actor_type"
    t.uuid "actor_id"
    t.integer "action", default: 0, null: false
    t.string "from_status"
    t.string "to_status"
    t.text "note"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_ticket_logs_on_business_type"
    t.index ["company_id", "ticket_id"], name: "index_ticket_logs_on_company_id_and_ticket_id"
    t.index ["company_id"], name: "index_ticket_logs_on_company_id"
    t.index ["discarded_at"], name: "index_ticket_logs_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_ticket_logs_on_lifecycle_status"
    t.index ["ticket_id"], name: "index_ticket_logs_on_ticket_id"
    t.index ["workflow_status"], name: "index_ticket_logs_on_workflow_status"
  end

  create_table "tickets", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "employee_id", null: false
    t.uuid "assigned_employee_id"
    t.uuid "category_id", null: false
    t.uuid "property_mapping_id"
    t.uuid "workflow_step_id"
    t.string "name", null: false
    t.text "description"
    t.integer "priority", default: 1, null: false
    t.string "external_id"
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
    t.datetime "sla_due_at"
    t.datetime "first_response_at"
    t.datetime "resolved_at"
    t.datetime "escalated_at"
    t.index ["assigned_employee_id"], name: "index_tickets_on_assigned_employee_id"
    t.index ["business_type"], name: "index_tickets_on_business_type"
    t.index ["category_id"], name: "index_tickets_on_category_id"
    t.index ["company_id", "assigned_employee_id"], name: "index_tickets_on_company_id_and_assigned_employee_id"
    t.index ["company_id", "sla_due_at"], name: "index_tickets_on_company_id_and_sla_due_at"
    t.index ["company_id", "updated_at"], name: "index_tickets_on_company_id_and_updated_at"
    t.index ["company_id", "workflow_status"], name: "index_tickets_on_company_id_and_workflow_status"
    t.index ["company_id"], name: "index_tickets_on_company_id"
    t.index ["discarded_at"], name: "index_tickets_on_discarded_at"
    t.index ["employee_id"], name: "index_tickets_on_employee_id"
    t.index ["external_id"], name: "index_tickets_on_external_id"
    t.index ["lifecycle_status"], name: "index_tickets_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_tickets_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_tickets_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_tickets_on_workflow_step_id"
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
    t.integer "status", default: 0, null: false
    t.string "gateway_reference"
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_transactions_on_branch_id"
    t.index ["business_type"], name: "index_transactions_on_business_type"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["code"], name: "index_transactions_on_code", unique: true
    t.index ["company_id"], name: "index_transactions_on_company_id"
    t.index ["discarded_at"], name: "index_transactions_on_discarded_at"
    t.index ["email"], name: "index_transactions_on_email", unique: true
    t.index ["external_id"], name: "index_transactions_on_external_id"
    t.index ["invoice_id"], name: "index_transactions_on_invoice_id"
    t.index ["lifecycle_status"], name: "index_transactions_on_lifecycle_status"
    t.index ["payment_method_id"], name: "index_transactions_on_payment_method_id"
    t.index ["property_mapping_id"], name: "index_transactions_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_transactions_on_workflow_status"
  end

  create_table "user_mfa_methods", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "method", default: 0, null: false
    t.string "secret"
    t.string "label"
    t.datetime "confirmed_at"
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "method"], name: "index_user_mfa_methods_on_user_id_and_method"
    t.index ["user_id", "revoked_at"], name: "index_user_mfa_methods_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_user_mfa_methods_on_user_id"
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
    t.string "external_id"
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
    t.index ["external_id"], name: "index_users_on_external_id"
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
    t.string "external_id"
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
    t.index ["branch_id"], name: "index_warehouses_on_branch_id"
    t.index ["business_type"], name: "index_warehouses_on_business_type"
    t.index ["category_id"], name: "index_warehouses_on_category_id"
    t.index ["code"], name: "index_warehouses_on_code", unique: true
    t.index ["company_id"], name: "index_warehouses_on_company_id"
    t.index ["discarded_at"], name: "index_warehouses_on_discarded_at"
    t.index ["email"], name: "index_warehouses_on_email", unique: true
    t.index ["external_id"], name: "index_warehouses_on_external_id"
    t.index ["lifecycle_status"], name: "index_warehouses_on_lifecycle_status"
    t.index ["property_mapping_id"], name: "index_warehouses_on_property_mapping_id"
    t.index ["workflow_status"], name: "index_warehouses_on_workflow_status"
  end

  create_table "webhook_deliveries", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "webhook_endpoint_id", null: false
    t.string "event_key", null: false
    t.jsonb "payload", default: {}
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 1, null: false
    t.integer "response_code"
    t.datetime "delivered_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_webhook_deliveries_on_company_id"
    t.index ["status", "created_at"], name: "index_webhook_deliveries_on_status_and_created_at"
    t.index ["webhook_endpoint_id", "created_at"], name: "index_webhook_deliveries_on_webhook_endpoint_id_and_created_at"
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "url", null: false
    t.string "secret"
    t.jsonb "event_keys", default: []
    t.string "description"
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_webhook_endpoints_on_business_type"
    t.index ["company_id", "is_active"], name: "index_webhook_endpoints_on_company_id_and_is_active"
    t.index ["company_id"], name: "index_webhook_endpoints_on_company_id"
    t.index ["discarded_at"], name: "index_webhook_endpoints_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_webhook_endpoints_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_webhook_endpoints_on_workflow_status"
  end

  create_table "work_centers", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "branch_id"
    t.string "name", null: false
    t.decimal "capacity_per_hour", precision: 15, scale: 4, default: "1.0", null: false
    t.bigint "cost_per_hour_cents", default: 0, null: false
    t.integer "currency", default: 840
    t.boolean "is_active", default: true, null: false
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata", default: {}
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_work_centers_on_branch_id"
    t.index ["business_type"], name: "index_work_centers_on_business_type"
    t.index ["company_id", "name"], name: "index_work_centers_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_work_centers_on_company_id"
    t.index ["discarded_at"], name: "index_work_centers_on_discarded_at"
    t.index ["lifecycle_status"], name: "index_work_centers_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_work_centers_on_workflow_status"
  end

  create_table "workflow_step_logs", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "workflow_id", null: false
    t.uuid "workflow_step_id", null: false
    t.uuid "employee_id"
    t.string "subject_type", null: false
    t.uuid "subject_id", null: false
    t.integer "outcome"
    t.text "note"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_workflow_step_logs_on_business_type"
    t.index ["company_id"], name: "index_workflow_step_logs_on_company_id"
    t.index ["discarded_at"], name: "index_workflow_step_logs_on_discarded_at"
    t.index ["employee_id"], name: "index_workflow_step_logs_on_employee_id"
    t.index ["external_id"], name: "index_workflow_step_logs_on_external_id"
    t.index ["lifecycle_status"], name: "index_workflow_step_logs_on_lifecycle_status"
    t.index ["subject_type", "subject_id"], name: "index_workflow_step_logs_on_subject"
    t.index ["workflow_id", "created_at"], name: "index_workflow_step_logs_on_workflow_id_and_created_at"
    t.index ["workflow_id", "workflow_step_id"], name: "index_workflow_step_logs_on_workflow_id_and_workflow_step_id"
    t.index ["workflow_id"], name: "index_workflow_step_logs_on_workflow_id"
    t.index ["workflow_status"], name: "index_workflow_step_logs_on_workflow_status"
    t.index ["workflow_step_id"], name: "index_workflow_step_logs_on_workflow_step_id"
  end

  create_table "workflow_steps", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "workflow_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.integer "position"
    t.string "text_color"
    t.string "background_color"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_workflow_steps_on_business_type"
    t.index ["code"], name: "index_workflow_steps_on_code", unique: true
    t.index ["company_id"], name: "index_workflow_steps_on_company_id"
    t.index ["discarded_at"], name: "index_workflow_steps_on_discarded_at"
    t.index ["external_id"], name: "index_workflow_steps_on_external_id"
    t.index ["lifecycle_status"], name: "index_workflow_steps_on_lifecycle_status"
    t.index ["workflow_id", "position"], name: "index_workflow_steps_on_workflow_id_and_position"
    t.index ["workflow_id"], name: "index_workflow_steps_on_workflow_id"
    t.index ["workflow_status"], name: "index_workflow_steps_on_workflow_status"
  end

  create_table "workflows", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "category_id", null: false
    t.string "name"
    t.text "description"
    t.string "code"
    t.integer "process_type"
    t.string "external_id"
    t.integer "lifecycle_status"
    t.integer "workflow_status"
    t.integer "business_type"
    t.datetime "expiration_date"
    t.jsonb "metadata"
    t.datetime "discarded_at"
    t.string "permission_resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_type"], name: "index_workflows_on_business_type"
    t.index ["category_id"], name: "index_workflows_on_category_id", unique: true
    t.index ["code"], name: "index_workflows_on_code", unique: true
    t.index ["company_id", "process_type"], name: "index_workflows_on_company_id_and_process_type"
    t.index ["company_id"], name: "index_workflows_on_company_id"
    t.index ["discarded_at"], name: "index_workflows_on_discarded_at"
    t.index ["external_id"], name: "index_workflows_on_external_id"
    t.index ["lifecycle_status"], name: "index_workflows_on_lifecycle_status"
    t.index ["workflow_status"], name: "index_workflows_on_workflow_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "address_branch_appointments", "addresses"
  add_foreign_key "address_branch_appointments", "branches"
  add_foreign_key "address_branch_appointments", "companies"
  add_foreign_key "address_company_appointments", "addresses"
  add_foreign_key "address_company_appointments", "companies"
  add_foreign_key "address_customer_appointments", "addresses"
  add_foreign_key "address_customer_appointments", "companies"
  add_foreign_key "address_customer_appointments", "customers"
  add_foreign_key "address_customer_group_appointments", "addresses"
  add_foreign_key "address_customer_group_appointments", "companies"
  add_foreign_key "address_customer_group_appointments", "customer_groups"
  add_foreign_key "address_department_appointments", "addresses"
  add_foreign_key "address_department_appointments", "companies"
  add_foreign_key "address_department_appointments", "departments"
  add_foreign_key "address_employee_appointments", "addresses"
  add_foreign_key "address_employee_appointments", "companies"
  add_foreign_key "address_employee_appointments", "employees"
  add_foreign_key "address_employee_group_appointments", "addresses"
  add_foreign_key "address_employee_group_appointments", "companies"
  add_foreign_key "address_employee_group_appointments", "employee_groups"
  add_foreign_key "address_user_appointments", "addresses"
  add_foreign_key "address_user_appointments", "companies"
  add_foreign_key "address_user_appointments", "users"
  add_foreign_key "analytics", "companies"
  add_foreign_key "api_keys", "companies"
  add_foreign_key "api_keys", "employees", column: "created_by_employee_id"
  add_foreign_key "applicant_interviews", "applicants"
  add_foreign_key "applicant_interviews", "companies"
  add_foreign_key "applicant_interviews", "employees"
  add_foreign_key "applicants", "companies"
  add_foreign_key "applicants", "job_openings"
  add_foreign_key "applicants", "stored_files", column: "resume_stored_file_id"
  add_foreign_key "applicants", "workflow_steps"
  add_foreign_key "attendance_balances", "companies"
  add_foreign_key "attendance_balances", "employees"
  add_foreign_key "attendance_config_logs", "attendance_configs"
  add_foreign_key "attendance_config_logs", "branches"
  add_foreign_key "attendance_config_logs", "companies"
  add_foreign_key "attendance_config_logs", "employees"
  add_foreign_key "attendance_configs", "branches"
  add_foreign_key "attendance_configs", "companies"
  add_foreign_key "attendance_days", "branches"
  add_foreign_key "attendance_days", "companies"
  add_foreign_key "attendance_days", "employees"
  add_foreign_key "attendance_leaves", "branches"
  add_foreign_key "attendance_leaves", "companies"
  add_foreign_key "attendance_leaves", "employees"
  add_foreign_key "attendance_leaves", "employees", column: "decided_by_id", on_delete: :nullify
  add_foreign_key "attendance_logs", "branches"
  add_foreign_key "attendance_logs", "companies"
  add_foreign_key "attendance_logs", "employees"
  add_foreign_key "attendance_months", "branches"
  add_foreign_key "attendance_months", "companies"
  add_foreign_key "attendance_months", "employees"
  add_foreign_key "attendance_requests", "branches"
  add_foreign_key "attendance_requests", "companies"
  add_foreign_key "attendance_requests", "employees"
  add_foreign_key "attendance_requests", "employees", column: "decided_by_id"
  add_foreign_key "bill_of_materials", "companies"
  add_foreign_key "bill_of_materials", "products"
  add_foreign_key "billing_schedules", "companies"
  add_foreign_key "billing_schedules", "subscription_groups"
  add_foreign_key "bom_lines", "bill_of_materials"
  add_foreign_key "bom_lines", "companies"
  add_foreign_key "bom_lines", "products", column: "component_product_id"
  add_foreign_key "branch_event_appointments", "branches"
  add_foreign_key "branch_event_appointments", "companies"
  add_foreign_key "branch_event_appointments", "events"
  add_foreign_key "branch_operation_appointments", "branches"
  add_foreign_key "branch_operation_appointments", "companies"
  add_foreign_key "branch_operation_appointments", "operations"
  add_foreign_key "branch_payment_method_appointments", "branches"
  add_foreign_key "branch_payment_method_appointments", "companies"
  add_foreign_key "branch_payment_method_appointments", "payment_methods"
  add_foreign_key "branch_subscription_plan_appointments", "branches"
  add_foreign_key "branch_subscription_plan_appointments", "companies"
  add_foreign_key "branch_subscription_plan_appointments", "subscription_plans"
  add_foreign_key "branch_tag_appointments", "branches"
  add_foreign_key "branch_tag_appointments", "companies"
  add_foreign_key "branch_tag_appointments", "tags"
  add_foreign_key "branches", "branches", column: "parent_branch_id"
  add_foreign_key "branches", "categories"
  add_foreign_key "branches", "companies"
  add_foreign_key "branches", "property_mappings"
  add_foreign_key "brand_profiles", "companies"
  add_foreign_key "brand_profiles", "stored_files", column: "logo_stored_file_id"
  add_foreign_key "brand_tag_appointments", "brands"
  add_foreign_key "brand_tag_appointments", "companies"
  add_foreign_key "brand_tag_appointments", "tags"
  add_foreign_key "brands", "categories"
  add_foreign_key "brands", "companies"
  add_foreign_key "brands", "property_mappings"
  add_foreign_key "budget_lines", "budgets"
  add_foreign_key "budget_lines", "companies"
  add_foreign_key "budget_lines", "ledger_accounts"
  add_foreign_key "budgets", "branches"
  add_foreign_key "budgets", "companies"
  add_foreign_key "budgets", "cost_centers"
  add_foreign_key "budgets", "fiscal_periods"
  add_foreign_key "budgets", "workflow_steps"
  add_foreign_key "cart_employee_appointments", "carts"
  add_foreign_key "cart_employee_appointments", "companies"
  add_foreign_key "cart_employee_appointments", "employees"
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
  add_foreign_key "channel_connections", "companies"
  add_foreign_key "channel_sync_logs", "channel_connections"
  add_foreign_key "channel_sync_logs", "companies"
  add_foreign_key "comment_mentions", "companies"
  add_foreign_key "comment_mentions", "employees"
  add_foreign_key "comment_mentions", "record_comments"
  add_foreign_key "commission_entries", "commission_plans"
  add_foreign_key "commission_entries", "companies"
  add_foreign_key "commission_entries", "employees"
  add_foreign_key "commission_entries", "invoices"
  add_foreign_key "commission_entries", "orders"
  add_foreign_key "commission_entries", "payrolls"
  add_foreign_key "commission_plans", "categories", column: "applies_to_category_id"
  add_foreign_key "commission_plans", "companies"
  add_foreign_key "commission_plans", "employee_groups", column: "applies_to_employee_group_id"
  add_foreign_key "commission_tiers", "commission_plans"
  add_foreign_key "commission_tiers", "companies"
  add_foreign_key "companies", "users"
  add_foreign_key "company_company_appointments", "companies", column: "child_company_id"
  add_foreign_key "company_company_appointments", "companies", column: "parent_company_id"
  add_foreign_key "company_daily_usages", "companies"
  add_foreign_key "company_entitlements", "companies"
  add_foreign_key "company_invoices", "companies"
  add_foreign_key "company_invoices", "company_orders"
  add_foreign_key "company_migration_logs", "companies"
  add_foreign_key "company_migration_logs", "company_migrations"
  add_foreign_key "company_migrations", "companies"
  add_foreign_key "company_migrations", "folders"
  add_foreign_key "company_monthly_usages", "companies"
  add_foreign_key "company_orders", "companies"
  add_foreign_key "company_orders", "users"
  add_foreign_key "company_payment_method_appointments", "companies"
  add_foreign_key "company_payment_method_appointments", "payment_methods"
  add_foreign_key "company_settings", "companies"
  add_foreign_key "company_tag_appointments", "companies"
  add_foreign_key "company_tag_appointments", "tags"
  add_foreign_key "company_ticket_comments", "companies"
  add_foreign_key "company_ticket_comments", "company_tickets"
  add_foreign_key "company_ticket_logs", "companies"
  add_foreign_key "company_ticket_logs", "company_tickets"
  add_foreign_key "company_tickets", "companies"
  add_foreign_key "company_tickets", "employees"
  add_foreign_key "company_tickets", "users", column: "assigned_user_id"
  add_foreign_key "company_transactions", "companies"
  add_foreign_key "company_transactions", "company_invoices"
  add_foreign_key "company_transactions", "company_payment_methods"
  add_foreign_key "company_usage_logs", "companies"
  add_foreign_key "company_usage_logs", "company_wallets"
  add_foreign_key "company_wallet_logs", "companies"
  add_foreign_key "company_wallet_logs", "company_wallets"
  add_foreign_key "company_wallets", "companies"
  add_foreign_key "cost_centers", "branches"
  add_foreign_key "cost_centers", "companies"
  add_foreign_key "cost_centers", "cost_centers", column: "parent_id"
  add_foreign_key "cost_centers", "employees", column: "manager_employee_id"
  add_foreign_key "course_enrollments", "companies"
  add_foreign_key "course_enrollments", "courses"
  add_foreign_key "course_enrollments", "employees"
  add_foreign_key "course_enrollments", "exams"
  add_foreign_key "course_lessons", "companies"
  add_foreign_key "course_lessons", "courses"
  add_foreign_key "courses", "companies"
  add_foreign_key "credit_profiles", "companies"
  add_foreign_key "credit_profiles", "customers"
  add_foreign_key "credit_profiles", "employees", column: "reviewed_by_employee_id"
  add_foreign_key "customer_customer_group_appointments", "companies"
  add_foreign_key "customer_customer_group_appointments", "customer_groups"
  add_foreign_key "customer_customer_group_appointments", "customers"
  add_foreign_key "customer_employee_appointments", "companies"
  add_foreign_key "customer_employee_appointments", "customers"
  add_foreign_key "customer_employee_appointments", "employees"
  add_foreign_key "customer_event_appointments", "companies"
  add_foreign_key "customer_event_appointments", "customers"
  add_foreign_key "customer_event_appointments", "events"
  add_foreign_key "customer_group_role_appointments", "companies"
  add_foreign_key "customer_group_role_appointments", "customer_groups"
  add_foreign_key "customer_group_role_appointments", "roles"
  add_foreign_key "customer_group_service_appointments", "companies"
  add_foreign_key "customer_group_service_appointments", "customer_groups"
  add_foreign_key "customer_group_service_appointments", "services"
  add_foreign_key "customer_group_tag_appointments", "companies"
  add_foreign_key "customer_group_tag_appointments", "customer_groups"
  add_foreign_key "customer_group_tag_appointments", "tags"
  add_foreign_key "customer_groups", "branches"
  add_foreign_key "customer_groups", "categories"
  add_foreign_key "customer_groups", "companies"
  add_foreign_key "customer_groups", "property_mappings"
  add_foreign_key "customer_membership_appointments", "companies"
  add_foreign_key "customer_membership_appointments", "customers"
  add_foreign_key "customer_membership_appointments", "memberships"
  add_foreign_key "customer_profiles", "branches"
  add_foreign_key "customer_profiles", "categories"
  add_foreign_key "customer_profiles", "companies"
  add_foreign_key "customer_profiles", "customers"
  add_foreign_key "customer_profiles", "property_mappings"
  add_foreign_key "customer_role_appointments", "companies"
  add_foreign_key "customer_role_appointments", "customers"
  add_foreign_key "customer_role_appointments", "roles"
  add_foreign_key "customer_service_appointments", "companies"
  add_foreign_key "customer_service_appointments", "customers"
  add_foreign_key "customer_service_appointments", "services"
  add_foreign_key "customer_subprofiles", "branches"
  add_foreign_key "customer_subprofiles", "categories"
  add_foreign_key "customer_subprofiles", "companies"
  add_foreign_key "customer_subprofiles", "customer_profiles"
  add_foreign_key "customer_subprofiles", "customers"
  add_foreign_key "customer_subprofiles", "property_mappings"
  add_foreign_key "customer_tag_appointments", "companies"
  add_foreign_key "customer_tag_appointments", "customers"
  add_foreign_key "customer_tag_appointments", "tags"
  add_foreign_key "customer_user_appointments", "companies"
  add_foreign_key "customer_user_appointments", "customers"
  add_foreign_key "customer_user_appointments", "users"
  add_foreign_key "customers", "branches"
  add_foreign_key "customers", "categories"
  add_foreign_key "customers", "companies"
  add_foreign_key "customers", "payment_terms"
  add_foreign_key "customers", "property_mappings"
  add_foreign_key "customers", "users"
  add_foreign_key "dashboards", "companies"
  add_foreign_key "data_exports", "companies"
  add_foreign_key "data_exports", "employees", column: "requested_by_employee_id"
  add_foreign_key "data_exports", "stored_files"
  add_foreign_key "data_retention_policies", "companies"
  add_foreign_key "data_subject_requests", "companies"
  add_foreign_key "data_subject_requests", "customers"
  add_foreign_key "data_subject_requests", "employees"
  add_foreign_key "data_subject_requests", "users"
  add_foreign_key "department_employee_appointments", "companies"
  add_foreign_key "department_employee_appointments", "departments"
  add_foreign_key "department_employee_appointments", "employees"
  add_foreign_key "department_role_appointments", "companies"
  add_foreign_key "department_role_appointments", "departments"
  add_foreign_key "department_role_appointments", "roles"
  add_foreign_key "department_tag_appointments", "companies"
  add_foreign_key "department_tag_appointments", "departments"
  add_foreign_key "department_tag_appointments", "tags"
  add_foreign_key "departments", "categories"
  add_foreign_key "departments", "companies"
  add_foreign_key "departments", "property_mappings"
  add_foreign_key "depreciation_entries", "companies"
  add_foreign_key "depreciation_entries", "fiscal_periods"
  add_foreign_key "depreciation_entries", "fixed_assets"
  add_foreign_key "depreciation_entries", "journal_entries"
  add_foreign_key "disbursement_batches", "branches"
  add_foreign_key "disbursement_batches", "companies"
  add_foreign_key "disbursement_batches", "stored_files"
  add_foreign_key "discount_groups", "companies"
  add_foreign_key "discounts", "companies"
  add_foreign_key "discounts", "customers"
  add_foreign_key "discounts", "discount_groups"
  add_foreign_key "discounts", "employees"
  add_foreign_key "discounts", "invoices"
  add_foreign_key "discounts", "orders"
  add_foreign_key "document_employee_appointments", "companies"
  add_foreign_key "document_employee_appointments", "documents"
  add_foreign_key "document_employee_appointments", "employees"
  add_foreign_key "document_tag_appointments", "companies"
  add_foreign_key "document_tag_appointments", "documents"
  add_foreign_key "document_tag_appointments", "tags"
  add_foreign_key "documents", "branches"
  add_foreign_key "documents", "categories"
  add_foreign_key "documents", "companies"
  add_foreign_key "documents", "property_mappings"
  add_foreign_key "employee_employee_appointments", "companies"
  add_foreign_key "employee_employee_appointments", "employees"
  add_foreign_key "employee_employee_appointments", "employees", column: "related_employee_id"
  add_foreign_key "employee_employee_group_appointments", "companies"
  add_foreign_key "employee_employee_group_appointments", "employee_groups"
  add_foreign_key "employee_employee_group_appointments", "employees"
  add_foreign_key "employee_event_appointments", "companies"
  add_foreign_key "employee_event_appointments", "employees"
  add_foreign_key "employee_event_appointments", "events"
  add_foreign_key "employee_event_group_appointments", "companies"
  add_foreign_key "employee_event_group_appointments", "employees"
  add_foreign_key "employee_event_group_appointments", "event_groups"
  add_foreign_key "employee_exam_appointments", "companies"
  add_foreign_key "employee_exam_appointments", "employees"
  add_foreign_key "employee_exam_appointments", "employees", column: "assigned_by_employee_id", on_delete: :nullify
  add_foreign_key "employee_exam_appointments", "employees", column: "graded_by_employee_id", on_delete: :nullify
  add_foreign_key "employee_exam_appointments", "exams"
  add_foreign_key "employee_facility_appointments", "companies"
  add_foreign_key "employee_facility_appointments", "employees"
  add_foreign_key "employee_facility_appointments", "facilities"
  add_foreign_key "employee_group_role_appointments", "companies"
  add_foreign_key "employee_group_role_appointments", "employee_groups"
  add_foreign_key "employee_group_role_appointments", "roles"
  add_foreign_key "employee_group_tag_appointments", "companies"
  add_foreign_key "employee_group_tag_appointments", "employee_groups"
  add_foreign_key "employee_group_tag_appointments", "tags"
  add_foreign_key "employee_groups", "branches"
  add_foreign_key "employee_groups", "categories"
  add_foreign_key "employee_groups", "companies"
  add_foreign_key "employee_groups", "employees", column: "manager_id", on_delete: :nullify
  add_foreign_key "employee_groups", "property_mappings"
  add_foreign_key "employee_manager_appointments", "companies"
  add_foreign_key "employee_manager_appointments", "employees"
  add_foreign_key "employee_manager_appointments", "employees", column: "manager_employee_id"
  add_foreign_key "employee_notification_reads", "companies"
  add_foreign_key "employee_notification_reads", "employees"
  add_foreign_key "employee_notification_reads", "notifications"
  add_foreign_key "employee_notification_tag_appointments", "companies"
  add_foreign_key "employee_notification_tag_appointments", "employees"
  add_foreign_key "employee_notification_tag_appointments", "notification_tags"
  add_foreign_key "employee_order_group_appointments", "companies"
  add_foreign_key "employee_order_group_appointments", "employees"
  add_foreign_key "employee_order_group_appointments", "order_groups"
  add_foreign_key "employee_product_appointments", "companies"
  add_foreign_key "employee_product_appointments", "employees"
  add_foreign_key "employee_product_appointments", "products"
  add_foreign_key "employee_profiles", "branches"
  add_foreign_key "employee_profiles", "categories"
  add_foreign_key "employee_profiles", "companies"
  add_foreign_key "employee_profiles", "employees"
  add_foreign_key "employee_profiles", "property_mappings"
  add_foreign_key "employee_project_appointments", "companies"
  add_foreign_key "employee_project_appointments", "employees"
  add_foreign_key "employee_project_appointments", "projects"
  add_foreign_key "employee_project_group_appointments", "companies"
  add_foreign_key "employee_project_group_appointments", "employees"
  add_foreign_key "employee_project_group_appointments", "project_groups"
  add_foreign_key "employee_question_appointments", "companies"
  add_foreign_key "employee_question_appointments", "employee_exam_appointments"
  add_foreign_key "employee_question_appointments", "employees", column: "graded_by_employee_id", on_delete: :nullify
  add_foreign_key "employee_question_appointments", "questions"
  add_foreign_key "employee_role_appointments", "companies"
  add_foreign_key "employee_role_appointments", "employees"
  add_foreign_key "employee_role_appointments", "roles"
  add_foreign_key "employee_service_appointments", "companies"
  add_foreign_key "employee_service_appointments", "employees"
  add_foreign_key "employee_service_appointments", "services"
  add_foreign_key "employee_subprofiles", "branches"
  add_foreign_key "employee_subprofiles", "categories"
  add_foreign_key "employee_subprofiles", "companies"
  add_foreign_key "employee_subprofiles", "employee_profiles"
  add_foreign_key "employee_subprofiles", "employees"
  add_foreign_key "employee_subprofiles", "property_mappings"
  add_foreign_key "employee_tag_appointments", "companies"
  add_foreign_key "employee_tag_appointments", "employees"
  add_foreign_key "employee_tag_appointments", "tags"
  add_foreign_key "employee_task_appointments", "companies"
  add_foreign_key "employee_task_appointments", "employees"
  add_foreign_key "employee_task_appointments", "tasks"
  add_foreign_key "employee_task_group_appointments", "companies"
  add_foreign_key "employee_task_group_appointments", "employees"
  add_foreign_key "employee_task_group_appointments", "task_groups"
  add_foreign_key "employees", "branches"
  add_foreign_key "employees", "categories"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "cost_centers"
  add_foreign_key "employees", "job_openings"
  add_foreign_key "employees", "property_mappings"
  add_foreign_key "employees", "users"
  add_foreign_key "event_config_logs", "categories"
  add_foreign_key "event_config_logs", "companies"
  add_foreign_key "event_config_logs", "employees"
  add_foreign_key "event_config_logs", "event_configs"
  add_foreign_key "event_configs", "categories"
  add_foreign_key "event_configs", "companies"
  add_foreign_key "event_facility_appointments", "companies"
  add_foreign_key "event_facility_appointments", "events"
  add_foreign_key "event_facility_appointments", "facilities"
  add_foreign_key "event_group_tag_appointments", "companies"
  add_foreign_key "event_group_tag_appointments", "event_groups"
  add_foreign_key "event_group_tag_appointments", "tags"
  add_foreign_key "event_groups", "branches"
  add_foreign_key "event_groups", "categories"
  add_foreign_key "event_groups", "companies"
  add_foreign_key "event_groups", "property_mappings"
  add_foreign_key "event_order_appointments", "companies"
  add_foreign_key "event_order_appointments", "events"
  add_foreign_key "event_order_appointments", "orders"
  add_foreign_key "event_service_appointments", "companies"
  add_foreign_key "event_service_appointments", "events"
  add_foreign_key "event_service_appointments", "services"
  add_foreign_key "event_stock_appointments", "companies"
  add_foreign_key "event_stock_appointments", "events"
  add_foreign_key "event_stock_appointments", "stocks"
  add_foreign_key "event_tag_appointments", "companies"
  add_foreign_key "event_tag_appointments", "events"
  add_foreign_key "event_tag_appointments", "tags"
  add_foreign_key "events", "branches"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "companies"
  add_foreign_key "events", "event_groups"
  add_foreign_key "events", "property_mappings"
  add_foreign_key "exam_question_appointments", "companies"
  add_foreign_key "exam_question_appointments", "exams"
  add_foreign_key "exam_question_appointments", "questions"
  add_foreign_key "exam_summaries", "companies"
  add_foreign_key "exam_summaries", "exams"
  add_foreign_key "exams", "companies"
  add_foreign_key "exchange_rates", "companies"
  add_foreign_key "facilities", "branches"
  add_foreign_key "facilities", "categories"
  add_foreign_key "facilities", "companies"
  add_foreign_key "facilities", "property_mappings"
  add_foreign_key "facility_facility_group_appointments", "companies"
  add_foreign_key "facility_facility_group_appointments", "facilities"
  add_foreign_key "facility_facility_group_appointments", "facility_groups"
  add_foreign_key "facility_group_tag_appointments", "companies"
  add_foreign_key "facility_group_tag_appointments", "facility_groups"
  add_foreign_key "facility_group_tag_appointments", "tags"
  add_foreign_key "facility_groups", "branches"
  add_foreign_key "facility_groups", "categories"
  add_foreign_key "facility_groups", "companies"
  add_foreign_key "facility_groups", "property_mappings"
  add_foreign_key "facility_tag_appointments", "companies"
  add_foreign_key "facility_tag_appointments", "facilities"
  add_foreign_key "facility_tag_appointments", "tags"
  add_foreign_key "fiscal_periods", "companies"
  add_foreign_key "fiscal_periods", "employees", column: "closed_by_employee_id"
  add_foreign_key "fixed_assets", "branches"
  add_foreign_key "fixed_assets", "companies"
  add_foreign_key "fixed_assets", "cost_centers"
  add_foreign_key "fixed_assets", "ledger_accounts"
  add_foreign_key "folders", "companies"
  add_foreign_key "idempotency_keys", "companies"
  add_foreign_key "identity_providers", "companies"
  add_foreign_key "import_logs", "companies"
  add_foreign_key "import_logs", "imports"
  add_foreign_key "imports", "categories", on_delete: :nullify
  add_foreign_key "imports", "companies"
  add_foreign_key "imports", "employees", column: "creator_id", on_delete: :nullify
  add_foreign_key "imports", "folders"
  add_foreign_key "invoice_reminders", "companies"
  add_foreign_key "invoice_reminders", "invoices"
  add_foreign_key "invoice_tag_appointments", "companies"
  add_foreign_key "invoice_tag_appointments", "invoices"
  add_foreign_key "invoice_tag_appointments", "tags"
  add_foreign_key "invoices", "billing_schedules"
  add_foreign_key "invoices", "branches"
  add_foreign_key "invoices", "categories"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "invoices", column: "credited_invoice_id"
  add_foreign_key "invoices", "orders"
  add_foreign_key "invoices", "payment_terms"
  add_foreign_key "invoices", "property_mappings"
  add_foreign_key "job_openings", "branches"
  add_foreign_key "job_openings", "companies"
  add_foreign_key "job_openings", "departments"
  add_foreign_key "journal_entries", "branches"
  add_foreign_key "journal_entries", "companies"
  add_foreign_key "journal_entries", "employees", column: "posted_by_employee_id"
  add_foreign_key "journal_entries", "fiscal_periods"
  add_foreign_key "journal_entries", "journal_entries", column: "reversal_of_id"
  add_foreign_key "journal_lines", "branches"
  add_foreign_key "journal_lines", "companies"
  add_foreign_key "journal_lines", "cost_centers"
  add_foreign_key "journal_lines", "customers"
  add_foreign_key "journal_lines", "departments"
  add_foreign_key "journal_lines", "employees"
  add_foreign_key "journal_lines", "journal_entries"
  add_foreign_key "journal_lines", "ledger_accounts"
  add_foreign_key "journal_lines", "products"
  add_foreign_key "journal_lines", "projects"
  add_foreign_key "journal_lines", "suppliers"
  add_foreign_key "kpi_configs", "branches", on_delete: :nullify
  add_foreign_key "kpi_configs", "categories", on_delete: :nullify
  add_foreign_key "kpi_configs", "companies"
  add_foreign_key "kpi_configs", "departments", on_delete: :nullify
  add_foreign_key "kpi_configs", "roles", on_delete: :nullify
  add_foreign_key "landed_cost_allocations", "companies"
  add_foreign_key "landed_cost_allocations", "landed_cost_charges"
  add_foreign_key "landed_cost_allocations", "products"
  add_foreign_key "landed_cost_allocations", "stocks"
  add_foreign_key "landed_cost_charges", "companies"
  add_foreign_key "landed_cost_charges", "stock_imports"
  add_foreign_key "landed_cost_charges", "suppliers"
  add_foreign_key "ledger_accounts", "companies"
  add_foreign_key "ledger_accounts", "ledger_accounts", column: "parent_id"
  add_foreign_key "loyalty_entries", "companies"
  add_foreign_key "loyalty_entries", "customers"
  add_foreign_key "loyalty_entries", "loyalty_programs"
  add_foreign_key "loyalty_programs", "companies"
  add_foreign_key "machine_readings", "companies"
  add_foreign_key "machine_readings", "work_centers"
  add_foreign_key "maintenance_checks", "companies"
  add_foreign_key "maintenance_checks", "maintenance_plans"
  add_foreign_key "maintenance_plans", "companies"
  add_foreign_key "maintenance_plans", "facilities"
  add_foreign_key "maintenance_plans", "fixed_assets"
  add_foreign_key "memberships", "branches"
  add_foreign_key "memberships", "categories"
  add_foreign_key "memberships", "companies"
  add_foreign_key "memberships", "property_mappings"
  add_foreign_key "mrp_runs", "companies"
  add_foreign_key "network_policies", "companies"
  add_foreign_key "non_conformances", "companies"
  add_foreign_key "non_conformances", "production_orders"
  add_foreign_key "non_conformances", "products"
  add_foreign_key "non_conformances", "quality_inspections"
  add_foreign_key "non_conformances", "stock_imports"
  add_foreign_key "notification_channels", "companies"
  add_foreign_key "notification_configs", "companies"
  add_foreign_key "notification_configs", "employees"
  add_foreign_key "notification_deliveries", "companies"
  add_foreign_key "notification_deliveries", "notification_channels"
  add_foreign_key "notification_deliveries", "notifications"
  add_foreign_key "notification_tag_appointments", "companies"
  add_foreign_key "notification_tag_appointments", "notification_tags"
  add_foreign_key "notification_tag_appointments", "notifications"
  add_foreign_key "notification_tags", "companies"
  add_foreign_key "notifications", "companies"
  add_foreign_key "operation_warehouse_appointments", "companies"
  add_foreign_key "operation_warehouse_appointments", "operations"
  add_foreign_key "operation_warehouse_appointments", "warehouses"
  add_foreign_key "operations", "companies"
  add_foreign_key "order_group_tag_appointments", "companies"
  add_foreign_key "order_group_tag_appointments", "order_groups"
  add_foreign_key "order_group_tag_appointments", "tags"
  add_foreign_key "order_groups", "branches"
  add_foreign_key "order_groups", "categories"
  add_foreign_key "order_groups", "companies"
  add_foreign_key "order_groups", "customers"
  add_foreign_key "order_groups", "property_mappings"
  add_foreign_key "order_pick_wave_appointments", "companies"
  add_foreign_key "order_pick_wave_appointments", "orders"
  add_foreign_key "order_pick_wave_appointments", "pick_waves", column: "pick_wave_id"
  add_foreign_key "order_product_appointments", "companies"
  add_foreign_key "order_product_appointments", "orders"
  add_foreign_key "order_product_appointments", "products"
  add_foreign_key "order_product_appointments", "stocks"
  add_foreign_key "order_product_group_appointments", "companies"
  add_foreign_key "order_product_group_appointments", "orders"
  add_foreign_key "order_product_group_appointments", "product_groups"
  add_foreign_key "order_product_group_appointments", "stocks"
  add_foreign_key "order_service_appointments", "companies"
  add_foreign_key "order_service_appointments", "orders"
  add_foreign_key "order_service_appointments", "services"
  add_foreign_key "order_service_appointments", "stocks"
  add_foreign_key "order_service_group_appointments", "companies"
  add_foreign_key "order_service_group_appointments", "orders"
  add_foreign_key "order_service_group_appointments", "service_groups"
  add_foreign_key "order_service_group_appointments", "stocks"
  add_foreign_key "order_subscription_plan_appointments", "companies"
  add_foreign_key "order_subscription_plan_appointments", "orders"
  add_foreign_key "order_subscription_plan_appointments", "stocks"
  add_foreign_key "order_subscription_plan_appointments", "subscription_plans"
  add_foreign_key "order_tag_appointments", "companies"
  add_foreign_key "order_tag_appointments", "orders"
  add_foreign_key "order_tag_appointments", "tags"
  add_foreign_key "orders", "branches"
  add_foreign_key "orders", "categories"
  add_foreign_key "orders", "channel_connections"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "employees", on_delete: :nullify
  add_foreign_key "orders", "payment_terms"
  add_foreign_key "orders", "price_lists"
  add_foreign_key "orders", "property_mappings"
  add_foreign_key "payment_terms", "companies"
  add_foreign_key "payroll_configs", "companies"
  add_foreign_key "payrolls", "attendance_months"
  add_foreign_key "payrolls", "branches"
  add_foreign_key "payrolls", "companies"
  add_foreign_key "payrolls", "cost_centers"
  add_foreign_key "payrolls", "disbursement_batches"
  add_foreign_key "payrolls", "employees"
  add_foreign_key "payrolls", "payroll_configs"
  add_foreign_key "permission_logs", "companies"
  add_foreign_key "permission_logs", "employees"
  add_foreign_key "permission_logs", "policies"
  add_foreign_key "permission_logs", "policy_role_appointments"
  add_foreign_key "permission_logs", "roles"
  add_foreign_key "pick_tasks", "companies"
  add_foreign_key "pick_tasks", "employees", column: "assigned_employee_id"
  add_foreign_key "pick_tasks", "orders"
  add_foreign_key "pick_tasks", "pick_waves", column: "pick_wave_id"
  add_foreign_key "pick_tasks", "stock_lots"
  add_foreign_key "pick_tasks", "stocks"
  add_foreign_key "pick_tasks", "storage_locations"
  add_foreign_key "pick_waves", "companies"
  add_foreign_key "pick_waves", "employees", column: "created_by_employee_id"
  add_foreign_key "pick_waves", "warehouses"
  add_foreign_key "policies", "branches"
  add_foreign_key "policies", "companies"
  add_foreign_key "policy_role_appointments", "companies"
  add_foreign_key "policy_role_appointments", "policies"
  add_foreign_key "policy_role_appointments", "roles"
  add_foreign_key "posting_rules", "companies"
  add_foreign_key "posting_rules", "ledger_accounts", column: "credit_ledger_account_id"
  add_foreign_key "posting_rules", "ledger_accounts", column: "debit_ledger_account_id"
  add_foreign_key "price_list_items", "companies"
  add_foreign_key "price_list_items", "price_lists"
  add_foreign_key "price_list_items", "products"
  add_foreign_key "price_list_items", "services"
  add_foreign_key "price_lists", "companies"
  add_foreign_key "price_lists", "customer_groups"
  add_foreign_key "product_barcodes", "companies"
  add_foreign_key "product_barcodes", "products"
  add_foreign_key "product_bundle_components", "companies"
  add_foreign_key "product_bundle_components", "product_bundles"
  add_foreign_key "product_bundle_components", "products", column: "component_product_id"
  add_foreign_key "product_bundles", "companies"
  add_foreign_key "product_bundles", "products"
  add_foreign_key "product_group_tag_appointments", "companies"
  add_foreign_key "product_group_tag_appointments", "product_groups"
  add_foreign_key "product_group_tag_appointments", "tags"
  add_foreign_key "product_groups", "branches"
  add_foreign_key "product_groups", "categories"
  add_foreign_key "product_groups", "companies"
  add_foreign_key "product_groups", "property_mappings"
  add_foreign_key "product_product_group_appointments", "companies"
  add_foreign_key "product_product_group_appointments", "product_groups"
  add_foreign_key "product_product_group_appointments", "products"
  add_foreign_key "product_tag_appointments", "companies"
  add_foreign_key "product_tag_appointments", "products"
  add_foreign_key "product_tag_appointments", "tags"
  add_foreign_key "production_operations", "companies"
  add_foreign_key "production_operations", "production_routings"
  add_foreign_key "production_operations", "work_centers"
  add_foreign_key "production_order_materials", "companies"
  add_foreign_key "production_order_materials", "production_orders"
  add_foreign_key "production_order_materials", "products"
  add_foreign_key "production_order_materials", "stock_lots"
  add_foreign_key "production_order_operations", "companies"
  add_foreign_key "production_order_operations", "employees"
  add_foreign_key "production_order_operations", "production_operations"
  add_foreign_key "production_order_operations", "production_orders"
  add_foreign_key "production_order_operations", "work_centers"
  add_foreign_key "production_orders", "bill_of_materials"
  add_foreign_key "production_orders", "companies"
  add_foreign_key "production_orders", "products"
  add_foreign_key "production_orders", "warehouses"
  add_foreign_key "production_routings", "bill_of_materials"
  add_foreign_key "production_routings", "companies"
  add_foreign_key "products", "branches"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "property_mappings"
  add_foreign_key "products", "suppliers", column: "default_supplier_id"
  add_foreign_key "products", "tax_codes"
  add_foreign_key "project_billing_terms", "companies"
  add_foreign_key "project_billing_terms", "projects"
  add_foreign_key "project_group_tag_appointments", "companies"
  add_foreign_key "project_group_tag_appointments", "project_groups"
  add_foreign_key "project_group_tag_appointments", "tags"
  add_foreign_key "project_groups", "branches"
  add_foreign_key "project_groups", "categories"
  add_foreign_key "project_groups", "companies"
  add_foreign_key "project_groups", "property_mappings"
  add_foreign_key "project_milestones", "companies"
  add_foreign_key "project_milestones", "invoices"
  add_foreign_key "project_milestones", "projects"
  add_foreign_key "project_tag_appointments", "companies"
  add_foreign_key "project_tag_appointments", "projects"
  add_foreign_key "project_tag_appointments", "tags"
  add_foreign_key "project_time_entries", "companies"
  add_foreign_key "project_time_entries", "employees"
  add_foreign_key "project_time_entries", "invoices"
  add_foreign_key "project_time_entries", "projects"
  add_foreign_key "project_time_entries", "tasks"
  add_foreign_key "projects", "branches"
  add_foreign_key "projects", "categories"
  add_foreign_key "projects", "companies"
  add_foreign_key "projects", "cost_centers"
  add_foreign_key "projects", "customers"
  add_foreign_key "projects", "employees", column: "manager_employee_id"
  add_foreign_key "projects", "project_groups"
  add_foreign_key "projects", "property_mappings"
  add_foreign_key "promo_grants", "companies"
  add_foreign_key "promo_grants", "promo_campaigns"
  add_foreign_key "property_mappings", "categories"
  add_foreign_key "property_mappings", "companies"
  add_foreign_key "purchase_item_tag_appointments", "companies"
  add_foreign_key "purchase_item_tag_appointments", "purchase_items"
  add_foreign_key "purchase_item_tag_appointments", "tags"
  add_foreign_key "purchase_items", "categories"
  add_foreign_key "purchase_items", "companies"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "property_mappings"
  add_foreign_key "purchase_match_appointments", "companies"
  add_foreign_key "purchase_match_appointments", "purchases"
  add_foreign_key "purchase_match_appointments", "purchases", column: "related_purchase_id"
  add_foreign_key "purchase_match_appointments", "stock_imports"
  add_foreign_key "purchase_parent_appointments", "companies"
  add_foreign_key "purchase_parent_appointments", "purchases"
  add_foreign_key "purchase_parent_appointments", "purchases", column: "related_purchase_id"
  add_foreign_key "purchase_purchase_item_appointments", "companies"
  add_foreign_key "purchase_purchase_item_appointments", "purchase_items"
  add_foreign_key "purchase_purchase_item_appointments", "purchases"
  add_foreign_key "purchase_tag_appointments", "companies"
  add_foreign_key "purchase_tag_appointments", "purchases"
  add_foreign_key "purchase_tag_appointments", "tags"
  add_foreign_key "purchases", "branches"
  add_foreign_key "purchases", "categories"
  add_foreign_key "purchases", "companies"
  add_foreign_key "purchases", "payment_terms"
  add_foreign_key "purchases", "property_mappings"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "warehouses"
  add_foreign_key "purchases", "workflow_steps"
  add_foreign_key "quality_checks", "companies"
  add_foreign_key "quality_checks", "quality_inspections"
  add_foreign_key "quality_inspections", "companies"
  add_foreign_key "quality_inspections", "employees", column: "inspector_employee_id"
  add_foreign_key "question_options", "companies"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "companies"
  add_foreign_key "record_comments", "companies"
  add_foreign_key "record_comments", "employees"
  add_foreign_key "refunds", "branches"
  add_foreign_key "refunds", "categories"
  add_foreign_key "refunds", "companies"
  add_foreign_key "refunds", "customers"
  add_foreign_key "refunds", "invoices"
  add_foreign_key "refunds", "orders"
  add_foreign_key "refunds", "payment_methods"
  add_foreign_key "refunds", "products"
  add_foreign_key "refunds", "property_mappings"
  add_foreign_key "refunds", "transactions"
  add_foreign_key "refunds", "workflow_steps"
  add_foreign_key "reorder_rules", "companies"
  add_foreign_key "reorder_rules", "products"
  add_foreign_key "reorder_rules", "warehouses"
  add_foreign_key "role_tag_appointments", "companies"
  add_foreign_key "role_tag_appointments", "roles"
  add_foreign_key "role_tag_appointments", "tags"
  add_foreign_key "roles", "branches"
  add_foreign_key "roles", "companies"
  add_foreign_key "scheduled_shifts", "branches"
  add_foreign_key "scheduled_shifts", "companies"
  add_foreign_key "scheduled_shifts", "employees"
  add_foreign_key "scheduled_shifts", "shift_templates"
  add_foreign_key "service_group_tag_appointments", "companies"
  add_foreign_key "service_group_tag_appointments", "service_groups"
  add_foreign_key "service_group_tag_appointments", "tags"
  add_foreign_key "service_groups", "branches"
  add_foreign_key "service_groups", "categories"
  add_foreign_key "service_groups", "companies"
  add_foreign_key "service_groups", "property_mappings"
  add_foreign_key "service_service_group_appointments", "companies"
  add_foreign_key "service_service_group_appointments", "service_groups"
  add_foreign_key "service_service_group_appointments", "services"
  add_foreign_key "service_tag_appointments", "companies"
  add_foreign_key "service_tag_appointments", "services"
  add_foreign_key "service_tag_appointments", "tags"
  add_foreign_key "service_visit_parts", "companies"
  add_foreign_key "service_visit_parts", "products"
  add_foreign_key "service_visit_parts", "service_visits"
  add_foreign_key "service_visit_parts", "stocks"
  add_foreign_key "service_visits", "companies"
  add_foreign_key "service_visits", "customers"
  add_foreign_key "service_visits", "employees", column: "assigned_employee_id"
  add_foreign_key "service_visits", "facilities"
  add_foreign_key "service_visits", "projects"
  add_foreign_key "services", "branches"
  add_foreign_key "services", "categories"
  add_foreign_key "services", "companies"
  add_foreign_key "services", "property_mappings"
  add_foreign_key "sessions", "users"
  add_foreign_key "shift_templates", "branches"
  add_foreign_key "shift_templates", "companies"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "signature_events", "companies"
  add_foreign_key "signature_events", "signature_requests"
  add_foreign_key "signature_requests", "companies"
  add_foreign_key "signature_requests", "documents"
  add_foreign_key "signature_requests", "employees", column: "requested_by_employee_id"
  add_foreign_key "signature_requests", "stored_files"
  add_foreign_key "statistic_tag_appointments", "companies"
  add_foreign_key "statistic_tag_appointments", "statistics"
  add_foreign_key "statistic_tag_appointments", "tags"
  add_foreign_key "stock_adjustment_stock_appointments", "companies"
  add_foreign_key "stock_adjustment_stock_appointments", "stock_adjustments"
  add_foreign_key "stock_adjustment_stock_appointments", "stocks"
  add_foreign_key "stock_adjustments", "branches"
  add_foreign_key "stock_adjustments", "categories"
  add_foreign_key "stock_adjustments", "companies"
  add_foreign_key "stock_adjustments", "property_mappings"
  add_foreign_key "stock_adjustments", "warehouses"
  add_foreign_key "stock_count_lines", "companies"
  add_foreign_key "stock_count_lines", "stock_counts"
  add_foreign_key "stock_count_lines", "stocks"
  add_foreign_key "stock_count_lines", "storage_locations"
  add_foreign_key "stock_counts", "companies"
  add_foreign_key "stock_counts", "employees", column: "created_by_employee_id"
  add_foreign_key "stock_counts", "warehouses"
  add_foreign_key "stock_export_stock_appointments", "companies"
  add_foreign_key "stock_export_stock_appointments", "stock_exports"
  add_foreign_key "stock_export_stock_appointments", "stocks"
  add_foreign_key "stock_export_tag_appointments", "companies"
  add_foreign_key "stock_export_tag_appointments", "stock_exports"
  add_foreign_key "stock_export_tag_appointments", "tags"
  add_foreign_key "stock_exports", "branches"
  add_foreign_key "stock_exports", "categories"
  add_foreign_key "stock_exports", "companies"
  add_foreign_key "stock_exports", "products"
  add_foreign_key "stock_exports", "property_mappings"
  add_foreign_key "stock_exports", "warehouses"
  add_foreign_key "stock_import_stock_appointments", "companies"
  add_foreign_key "stock_import_stock_appointments", "stock_imports"
  add_foreign_key "stock_import_stock_appointments", "stocks"
  add_foreign_key "stock_import_tag_appointments", "companies"
  add_foreign_key "stock_import_tag_appointments", "stock_imports"
  add_foreign_key "stock_import_tag_appointments", "tags"
  add_foreign_key "stock_imports", "branches"
  add_foreign_key "stock_imports", "categories"
  add_foreign_key "stock_imports", "companies"
  add_foreign_key "stock_imports", "products"
  add_foreign_key "stock_imports", "property_mappings"
  add_foreign_key "stock_imports", "purchases"
  add_foreign_key "stock_imports", "warehouses"
  add_foreign_key "stock_lots", "companies"
  add_foreign_key "stock_lots", "products"
  add_foreign_key "stock_lots", "suppliers"
  add_foreign_key "stock_lots", "warehouses"
  add_foreign_key "stock_pendings", "companies"
  add_foreign_key "stock_pendings", "products"
  add_foreign_key "stock_pendings", "stocks"
  add_foreign_key "stock_pendings", "warehouses"
  add_foreign_key "stock_serials", "companies"
  add_foreign_key "stock_serials", "orders", column: "sold_order_id"
  add_foreign_key "stock_serials", "stock_lots"
  add_foreign_key "stock_serials", "stocks"
  add_foreign_key "stock_serials", "storage_locations"
  add_foreign_key "stock_tag_appointments", "companies"
  add_foreign_key "stock_tag_appointments", "stocks"
  add_foreign_key "stock_tag_appointments", "tags"
  add_foreign_key "stock_transactions", "branches"
  add_foreign_key "stock_transactions", "categories"
  add_foreign_key "stock_transactions", "companies"
  add_foreign_key "stock_transactions", "products"
  add_foreign_key "stock_transactions", "property_mappings"
  add_foreign_key "stock_transactions", "stock_lots"
  add_foreign_key "stock_transactions", "stock_serials"
  add_foreign_key "stock_transactions", "storage_locations"
  add_foreign_key "stock_transactions", "warehouses"
  add_foreign_key "stock_transfer_stock_appointments", "companies"
  add_foreign_key "stock_transfer_stock_appointments", "stock_transfers"
  add_foreign_key "stock_transfer_stock_appointments", "stocks"
  add_foreign_key "stock_transfer_tag_appointments", "companies"
  add_foreign_key "stock_transfer_tag_appointments", "stock_transfers"
  add_foreign_key "stock_transfer_tag_appointments", "tags"
  add_foreign_key "stock_transfers", "branches"
  add_foreign_key "stock_transfers", "categories"
  add_foreign_key "stock_transfers", "companies"
  add_foreign_key "stock_transfers", "products"
  add_foreign_key "stock_transfers", "property_mappings"
  add_foreign_key "stock_transfers", "warehouses"
  add_foreign_key "stock_transfers", "warehouses", column: "destination_warehouse_id"
  add_foreign_key "stocks", "branches"
  add_foreign_key "stocks", "categories"
  add_foreign_key "stocks", "companies"
  add_foreign_key "stocks", "products"
  add_foreign_key "stocks", "property_mappings"
  add_foreign_key "stocks", "warehouses"
  add_foreign_key "storage_locations", "companies"
  add_foreign_key "storage_locations", "storage_locations", column: "parent_id"
  add_foreign_key "storage_locations", "warehouses"
  add_foreign_key "stored_files", "companies"
  add_foreign_key "stored_files", "folders"
  add_foreign_key "stored_files", "stored_files", column: "parent_stored_file_id"
  add_foreign_key "subcontract_orders", "companies"
  add_foreign_key "subcontract_orders", "products"
  add_foreign_key "subcontract_orders", "purchases"
  add_foreign_key "subcontract_orders", "suppliers"
  add_foreign_key "subscription_group_subscription_plan_appointments", "companies"
  add_foreign_key "subscription_group_subscription_plan_appointments", "subscription_groups"
  add_foreign_key "subscription_group_subscription_plan_appointments", "subscription_plans"
  add_foreign_key "subscription_group_tag_appointments", "companies"
  add_foreign_key "subscription_group_tag_appointments", "subscription_groups"
  add_foreign_key "subscription_group_tag_appointments", "tags"
  add_foreign_key "subscription_groups", "branches"
  add_foreign_key "subscription_groups", "companies"
  add_foreign_key "subscription_groups", "subscription_groups"
  add_foreign_key "subscription_groups", "subscription_plans"
  add_foreign_key "subscription_plans", "branches"
  add_foreign_key "subscription_plans", "companies"
  add_foreign_key "supplier_tag_appointments", "companies"
  add_foreign_key "supplier_tag_appointments", "suppliers"
  add_foreign_key "supplier_tag_appointments", "tags"
  add_foreign_key "suppliers", "categories"
  add_foreign_key "suppliers", "companies"
  add_foreign_key "suppliers", "payment_terms"
  add_foreign_key "suppliers", "property_mappings"
  add_foreign_key "systems", "companies"
  add_foreign_key "table_config_logs", "categories"
  add_foreign_key "table_config_logs", "companies"
  add_foreign_key "table_config_logs", "employees"
  add_foreign_key "table_config_logs", "property_mappings"
  add_foreign_key "table_config_logs", "table_configs"
  add_foreign_key "table_configs", "categories"
  add_foreign_key "table_configs", "companies"
  add_foreign_key "table_configs", "property_mappings"
  add_foreign_key "tag_task_appointments", "companies"
  add_foreign_key "tag_task_appointments", "tags"
  add_foreign_key "tag_task_appointments", "tasks"
  add_foreign_key "tag_task_group_appointments", "companies"
  add_foreign_key "tag_task_group_appointments", "tags"
  add_foreign_key "tag_task_group_appointments", "task_groups"
  add_foreign_key "tag_transaction_appointments", "companies"
  add_foreign_key "tag_transaction_appointments", "tags"
  add_foreign_key "tag_transaction_appointments", "transactions"
  add_foreign_key "tag_warehouse_appointments", "companies"
  add_foreign_key "tag_warehouse_appointments", "tags"
  add_foreign_key "tag_warehouse_appointments", "warehouses"
  add_foreign_key "tags", "companies"
  add_foreign_key "task_dependencies", "companies"
  add_foreign_key "task_dependencies", "tasks", column: "predecessor_task_id"
  add_foreign_key "task_dependencies", "tasks", column: "successor_task_id"
  add_foreign_key "task_groups", "branches"
  add_foreign_key "task_groups", "categories"
  add_foreign_key "task_groups", "companies"
  add_foreign_key "task_groups", "property_mappings"
  add_foreign_key "tasks", "branches"
  add_foreign_key "tasks", "categories"
  add_foreign_key "tasks", "companies"
  add_foreign_key "tasks", "project_milestones"
  add_foreign_key "tasks", "property_mappings"
  add_foreign_key "tasks", "task_groups"
  add_foreign_key "tasks", "tasks", column: "parent_task_id"
  add_foreign_key "tax_codes", "companies"
  add_foreign_key "tax_codes", "ledger_accounts"
  add_foreign_key "tax_configs", "companies"
  add_foreign_key "ticket_comments", "companies"
  add_foreign_key "ticket_comments", "employees"
  add_foreign_key "ticket_comments", "tickets"
  add_foreign_key "ticket_logs", "companies"
  add_foreign_key "ticket_logs", "tickets"
  add_foreign_key "tickets", "categories"
  add_foreign_key "tickets", "companies"
  add_foreign_key "tickets", "employees"
  add_foreign_key "tickets", "employees", column: "assigned_employee_id"
  add_foreign_key "tickets", "property_mappings"
  add_foreign_key "tickets", "workflow_steps"
  add_foreign_key "transactions", "branches"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "companies"
  add_foreign_key "transactions", "invoices"
  add_foreign_key "transactions", "payment_methods"
  add_foreign_key "transactions", "property_mappings"
  add_foreign_key "user_mfa_methods", "users"
  add_foreign_key "users", "users", column: "parent_user_id"
  add_foreign_key "warehouses", "branches"
  add_foreign_key "warehouses", "categories"
  add_foreign_key "warehouses", "companies"
  add_foreign_key "warehouses", "property_mappings"
  add_foreign_key "webhook_deliveries", "companies"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "companies"
  add_foreign_key "work_centers", "branches"
  add_foreign_key "work_centers", "companies"
  add_foreign_key "workflow_step_logs", "companies"
  add_foreign_key "workflow_step_logs", "employees"
  add_foreign_key "workflow_step_logs", "workflow_steps"
  add_foreign_key "workflow_step_logs", "workflows"
  add_foreign_key "workflow_steps", "companies"
  add_foreign_key "workflow_steps", "workflows"
  add_foreign_key "workflows", "categories"
  add_foreign_key "workflows", "companies"
end
