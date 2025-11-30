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

ActiveRecord::Schema[8.0].define(version: 2025_11_30_133659) do
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

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "alpha2"
    t.string "alpha3"
    t.string "continent"
    t.string "nationality"
    t.string "region"
    t.decimal "longitude"
    t.decimal "latitude"
    t.integer "level_total"
    t.string "level_1"
    t.string "level_2"
    t.string "level_3"
    t.string "level_4"
    t.string "level_5"
    t.string "level_6"
    t.string "level_7"
    t.string "level_8"
    t.string "level_9"
    t.string "level_10"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alpha2"], name: "index_addresses_on_alpha2"
    t.index ["alpha3"], name: "index_addresses_on_alpha3"
    t.index ["continent"], name: "index_addresses_on_continent"
    t.index ["level_1"], name: "index_addresses_on_level_1"
    t.index ["level_10"], name: "index_addresses_on_level_10"
    t.index ["level_2"], name: "index_addresses_on_level_2"
    t.index ["level_3"], name: "index_addresses_on_level_3"
    t.index ["level_4"], name: "index_addresses_on_level_4"
    t.index ["level_5"], name: "index_addresses_on_level_5"
    t.index ["level_6"], name: "index_addresses_on_level_6"
    t.index ["level_7"], name: "index_addresses_on_level_7"
    t.index ["level_8"], name: "index_addresses_on_level_8"
    t.index ["level_9"], name: "index_addresses_on_level_9"
    t.index ["nationality"], name: "index_addresses_on_nationality"
    t.index ["region"], name: "index_addresses_on_region"
  end

  create_table "answers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "question_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_answers_on_discarded_at"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "bookings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "appoint_from_type"
    t.uuid "appoint_from_id"
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_bookings_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_bookings_on_appoint_to"
    t.index ["company_group_id"], name: "index_bookings_on_company_group_id"
    t.index ["company_id"], name: "index_bookings_on_company_id"
    t.index ["discarded_at"], name: "index_bookings_on_discarded_at"
  end

  create_table "brands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_brands_on_discarded_at"
  end

  create_table "cart_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_cart_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_cart_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_cart_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_cart_appointments_on_appoint_to"
    t.index ["cart_id"], name: "index_cart_appointments_on_cart_id"
    t.index ["discarded_at"], name: "index_cart_appointments_on_discarded_at"
  end

  create_table "cart_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_cart_groups_on_company_group_id"
    t.index ["company_id"], name: "index_cart_groups_on_company_id"
    t.index ["discarded_at"], name: "index_cart_groups_on_discarded_at"
  end

  create_table "carts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "cart_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "sku"
    t.string "barcode"
    t.string "upc"
    t.string "ean"
    t.string "manufacturer_code"
    t.string "serial_number"
    t.string "batch_number"
    t.datetime "expiration_date"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_carts_on_barcode"
    t.index ["cart_group_id"], name: "index_carts_on_cart_group_id"
    t.index ["company_group_id"], name: "index_carts_on_company_group_id"
    t.index ["company_id"], name: "index_carts_on_company_id"
    t.index ["discarded_at"], name: "index_carts_on_discarded_at"
    t.index ["ean"], name: "index_carts_on_ean"
    t.index ["serial_number"], name: "index_carts_on_serial_number"
    t.index ["sku"], name: "index_carts_on_sku"
    t.index ["upc"], name: "index_carts_on_upc"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "parent_company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "ownership_type"
    t.integer "business_type"
    t.integer "currency"
    t.string "registration_number"
    t.string "vat_id"
    t.string "address_line_1"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.string "email"
    t.string "phone_number"
    t.string "website"
    t.integer "employee_count"
    t.integer "fiscal_year_end_month"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_companies_on_company_group_id"
    t.index ["discarded_at"], name: "index_companies_on_discarded_at"
    t.index ["parent_company_id"], name: "index_companies_on_parent_company_id"
  end

  create_table "company_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "ownership_type"
    t.integer "business_type"
    t.integer "currency"
    t.string "registration_number"
    t.string "vat_id"
    t.string "address_line_1"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.string "email"
    t.string "phone_number"
    t.string "website"
    t.integer "employee_count"
    t.integer "fiscal_year_end_month"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_company_groups_on_discarded_at"
    t.index ["user_id"], name: "index_company_groups_on_user_id"
  end

  create_table "customer_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_customer_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_customer_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_customer_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_customer_appointments_on_appoint_to"
    t.index ["customer_id"], name: "index_customer_appointments_on_customer_id"
    t.index ["discarded_at"], name: "index_customer_appointments_on_discarded_at"
  end

  create_table "customer_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_customer_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_customer_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_customer_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_customer_group_appointments_on_appoint_to"
    t.index ["customer_group_id"], name: "index_customer_group_appointments_on_customer_group_id"
    t.index ["discarded_at"], name: "index_customer_group_appointments_on_discarded_at"
  end

  create_table "customer_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_customer_groups_on_company_group_id"
    t.index ["company_id"], name: "index_customer_groups_on_company_id"
    t.index ["discarded_at"], name: "index_customer_groups_on_discarded_at"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_customers_on_company_group_id"
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "employee_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_employee_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_employee_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_employee_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_employee_appointments_on_appoint_to"
    t.index ["employee_id"], name: "index_employee_appointments_on_employee_id"
  end

  create_table "employee_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_employee_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_employee_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_employee_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_employee_group_appointments_on_appoint_to"
    t.index ["employee_group_id"], name: "index_employee_group_appointments_on_employee_group_id"
  end

  create_table "employee_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_employee_groups_on_company_group_id"
    t.index ["company_id"], name: "index_employee_groups_on_company_id"
    t.index ["discarded_at"], name: "index_employee_groups_on_discarded_at"
  end

  create_table "employees", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_employees_on_company_group_id"
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["discarded_at"], name: "index_employees_on_discarded_at"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "event_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "appoint_from_type", null: false
    t.uuid "appoint_from_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type", null: false
    t.uuid "appoint_for_id", null: false
    t.string "appoint_by_type", null: false
    t.uuid "appoint_by_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_event_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_event_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_event_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_event_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_event_appointments_on_discarded_at"
    t.index ["event_id"], name: "index_event_appointments_on_event_id"
  end

  create_table "event_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_group_id", null: false
    t.string "appoint_from_type", null: false
    t.uuid "appoint_from_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type", null: false
    t.uuid "appoint_for_id", null: false
    t.string "appoint_by_type", null: false
    t.uuid "appoint_by_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_event_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_event_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_event_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_event_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_event_group_appointments_on_discarded_at"
    t.index ["event_group_id"], name: "index_event_group_appointments_on_event_group_id"
  end

  create_table "event_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_event_groups_on_company_group_id"
    t.index ["company_id"], name: "index_event_groups_on_company_id"
    t.index ["discarded_at"], name: "index_event_groups_on_discarded_at"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_group_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_events_on_company_group_id"
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
  end

  create_table "exam_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_exam_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_exam_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_exam_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_exam_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_exam_appointments_on_discarded_at"
    t.index ["exam_id"], name: "index_exam_appointments_on_exam_id"
  end

  create_table "exam_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_exam_groups_on_company_group_id"
    t.index ["company_id"], name: "index_exam_groups_on_company_id"
    t.index ["discarded_at"], name: "index_exam_groups_on_discarded_at"
  end

  create_table "exams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "exam_group_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_exams_on_company_group_id"
    t.index ["company_id"], name: "index_exams_on_company_id"
    t.index ["discarded_at"], name: "index_exams_on_discarded_at"
    t.index ["exam_group_id"], name: "index_exams_on_exam_group_id"
  end

  create_table "facilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_facilities_on_company_group_id"
    t.index ["company_id"], name: "index_facilities_on_company_id"
    t.index ["discarded_at"], name: "index_facilities_on_discarded_at"
  end

  create_table "facility_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_facility_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_facility_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_facility_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_facility_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_facility_appointments_on_discarded_at"
    t.index ["facility_id"], name: "index_facility_appointments_on_facility_id"
  end

  create_table "facility_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_facility_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_facility_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_facility_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_facility_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_facility_group_appointments_on_discarded_at"
    t.index ["facility_group_id"], name: "index_facility_group_appointments_on_facility_group_id"
  end

  create_table "facility_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_facility_groups_on_company_group_id"
    t.index ["company_id"], name: "index_facility_groups_on_company_id"
    t.index ["discarded_at"], name: "index_facility_groups_on_discarded_at"
  end

  create_table "inventories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_inventories_on_company_group_id"
    t.index ["company_id"], name: "index_inventories_on_company_id"
    t.index ["discarded_at"], name: "index_inventories_on_discarded_at"
  end

  create_table "inventory_item_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inventory_item_id", null: false
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_inventory_item_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_inventory_item_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_inventory_item_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_inventory_item_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_inventory_item_appointments_on_discarded_at"
    t.index ["inventory_item_id"], name: "index_inventory_item_appointments_on_inventory_item_id"
  end

  create_table "inventory_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inventory_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "sku"
    t.string "barcode"
    t.string "upc"
    t.string "ean"
    t.string "manufacturer_code"
    t.string "serial_number"
    t.string "batch_number"
    t.datetime "expiration_date"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_inventory_items_on_barcode"
    t.index ["discarded_at"], name: "index_inventory_items_on_discarded_at"
    t.index ["ean"], name: "index_inventory_items_on_ean"
    t.index ["inventory_id"], name: "index_inventory_items_on_inventory_id"
    t.index ["serial_number"], name: "index_inventory_items_on_serial_number"
    t.index ["sku"], name: "index_inventory_items_on_sku"
    t.index ["upc"], name: "index_inventory_items_on_upc"
  end

  create_table "inventory_transaction_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inventory_transaction_id", null: false
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_inventory_transaction_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_inventory_transaction_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_inventory_transaction_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_inventory_transaction_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_inventory_transaction_appointments_on_discarded_at"
    t.index ["inventory_transaction_id"], name: "idx_on_inventory_transaction_id_49862a2fce"
  end

  create_table "inventory_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_inventory_transactions_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_inventory_transactions_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_inventory_transactions_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_inventory_transactions_on_appoint_to"
    t.index ["company_group_id"], name: "index_inventory_transactions_on_company_group_id"
    t.index ["company_id"], name: "index_inventory_transactions_on_company_id"
    t.index ["discarded_at"], name: "index_inventory_transactions_on_discarded_at"
  end

  create_table "invoices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "currency"
    t.integer "duration"
    t.string "number"
    t.string "total"
    t.datetime "due_date"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_invoices_on_discarded_at"
    t.index ["order_id"], name: "index_invoices_on_order_id"
  end

  create_table "notification_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_notification_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_notification_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_notification_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_notification_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_notification_appointments_on_discarded_at"
    t.index ["notification_id"], name: "index_notification_appointments_on_notification_id"
  end

  create_table "notification_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_notification_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_notification_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_notification_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_notification_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_notification_group_appointments_on_discarded_at"
    t.index ["notification_group_id"], name: "index_notification_group_appointments_on_notification_group_id"
  end

  create_table "notification_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_notification_groups_on_company_group_id"
    t.index ["company_id"], name: "index_notification_groups_on_company_id"
    t.index ["discarded_at"], name: "index_notification_groups_on_discarded_at"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "notification_group_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_notifications_on_company_group_id"
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["discarded_at"], name: "index_notifications_on_discarded_at"
    t.index ["notification_group_id"], name: "index_notifications_on_notification_group_id"
  end

  create_table "order_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_order_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_order_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_order_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_order_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_order_appointments_on_discarded_at"
    t.index ["order_id"], name: "index_order_appointments_on_order_id"
  end

  create_table "order_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_order_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_order_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_order_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_order_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_order_group_appointments_on_discarded_at"
    t.index ["order_group_id"], name: "index_order_group_appointments_on_order_group_id"
  end

  create_table "order_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "customer_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "currency"
    t.integer "duration"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_order_groups_on_company_group_id"
    t.index ["company_id"], name: "index_order_groups_on_company_id"
    t.index ["customer_id"], name: "index_order_groups_on_customer_id"
    t.index ["discarded_at"], name: "index_order_groups_on_discarded_at"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "customer_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "sku"
    t.string "barcode"
    t.string "upc"
    t.string "ean"
    t.string "manufacturer_code"
    t.string "serial_number"
    t.string "batch_number"
    t.datetime "expiration_date"
    t.integer "currency"
    t.integer "duration"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_orders_on_barcode"
    t.index ["company_group_id"], name: "index_orders_on_company_group_id"
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["ean"], name: "index_orders_on_ean"
    t.index ["serial_number"], name: "index_orders_on_serial_number"
    t.index ["sku"], name: "index_orders_on_sku"
    t.index ["upc"], name: "index_orders_on_upc"
  end

  create_table "payment_method_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "payment_method_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_payment_method_appointments_on_company_group_id"
    t.index ["company_id"], name: "index_payment_method_appointments_on_company_id"
    t.index ["discarded_at"], name: "index_payment_method_appointments_on_discarded_at"
    t.index ["payment_method_id"], name: "index_payment_method_appointments_on_payment_method_id"
  end

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "currency"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_payment_methods_on_discarded_at"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "invoice_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "currency"
    t.integer "duration"
    t.decimal "exchange_rate"
    t.decimal "amount"
    t.string "payment_method"
    t.string "gateway_details"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_payments_on_discarded_at"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "period_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "period_id", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_period_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_period_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_period_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_period_appointments_on_appoint_to"
    t.index ["period_id"], name: "index_period_appointments_on_period_id"
  end

  create_table "periods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "duration"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "expire_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_periods_on_company_group_id"
    t.index ["company_id"], name: "index_periods_on_company_id"
    t.index ["discarded_at"], name: "index_periods_on_discarded_at"
  end

  create_table "policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "resource"
    t.string "action"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_policies_on_company_group_id"
    t.index ["company_id"], name: "index_policies_on_company_id"
    t.index ["discarded_at"], name: "index_policies_on_discarded_at"
  end

  create_table "policy_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_policy_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_policy_appointments_on_discarded_at"
    t.index ["policy_id"], name: "index_policy_appointments_on_policy_id"
  end

  create_table "product_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_product_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_product_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_product_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_product_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_product_appointments_on_discarded_at"
    t.index ["product_id"], name: "index_product_appointments_on_product_id"
  end

  create_table "product_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_product_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_product_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_product_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_product_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_product_group_appointments_on_discarded_at"
    t.index ["product_group_id"], name: "index_product_group_appointments_on_product_group_id"
  end

  create_table "product_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_product_groups_on_company_group_id"
    t.index ["company_id"], name: "index_product_groups_on_company_id"
    t.index ["discarded_at"], name: "index_product_groups_on_discarded_at"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "brand_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "sku"
    t.string "barcode"
    t.string "upc"
    t.string "ean"
    t.string "manufacturer_code"
    t.string "serial_number"
    t.string "batch_number"
    t.datetime "expiration_date"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_products_on_barcode"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["company_group_id"], name: "index_products_on_company_group_id"
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["ean"], name: "index_products_on_ean"
    t.index ["serial_number"], name: "index_products_on_serial_number"
    t.index ["sku"], name: "index_products_on_sku"
    t.index ["upc"], name: "index_products_on_upc"
  end

  create_table "project_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_project_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_project_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_project_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_project_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_project_appointments_on_discarded_at"
    t.index ["project_id"], name: "index_project_appointments_on_project_id"
  end

  create_table "project_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_project_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_project_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_project_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_project_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_project_group_appointments_on_discarded_at"
    t.index ["project_group_id"], name: "index_project_group_appointments_on_project_group_id"
  end

  create_table "project_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_project_groups_on_company_group_id"
    t.index ["company_id"], name: "index_project_groups_on_company_id"
    t.index ["discarded_at"], name: "index_project_groups_on_discarded_at"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "project_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_projects_on_company_group_id"
    t.index ["company_id"], name: "index_projects_on_company_id"
    t.index ["discarded_at"], name: "index_projects_on_discarded_at"
    t.index ["project_group_id"], name: "index_projects_on_project_group_id"
  end

  create_table "purchase_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "purchase_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.string "sku"
    t.string "barcode"
    t.string "upc"
    t.string "ean"
    t.string "manufacturer_code"
    t.string "serial_number"
    t.string "batch_number"
    t.datetime "expiration_date"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_purchase_items_on_barcode"
    t.index ["discarded_at"], name: "index_purchase_items_on_discarded_at"
    t.index ["ean"], name: "index_purchase_items_on_ean"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
    t.index ["serial_number"], name: "index_purchase_items_on_serial_number"
    t.index ["sku"], name: "index_purchase_items_on_sku"
    t.index ["upc"], name: "index_purchase_items_on_upc"
  end

  create_table "purchases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_purchases_on_company_group_id"
    t.index ["company_id"], name: "index_purchases_on_company_id"
    t.index ["discarded_at"], name: "index_purchases_on_discarded_at"
  end

  create_table "questions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_questions_on_company_group_id"
    t.index ["company_id"], name: "index_questions_on_company_id"
    t.index ["discarded_at"], name: "index_questions_on_discarded_at"
  end

  create_table "role_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "role_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_role_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_role_appointments_on_discarded_at"
    t.index ["role_id"], name: "index_role_appointments_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_roles_on_company_group_id"
    t.index ["company_id"], name: "index_roles_on_company_id"
    t.index ["discarded_at"], name: "index_roles_on_discarded_at"
  end

  create_table "service_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_service_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_service_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_service_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_service_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_service_appointments_on_discarded_at"
    t.index ["service_id"], name: "index_service_appointments_on_service_id"
  end

  create_table "service_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_service_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_service_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_service_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_service_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_service_group_appointments_on_discarded_at"
    t.index ["service_group_id"], name: "index_service_group_appointments_on_service_group_id"
  end

  create_table "service_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_service_groups_on_company_group_id"
    t.index ["company_id"], name: "index_service_groups_on_company_id"
    t.index ["discarded_at"], name: "index_service_groups_on_discarded_at"
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "duration"
    t.datetime "start_at"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_services_on_company_group_id"
    t.index ["company_id"], name: "index_services_on_company_id"
    t.index ["discarded_at"], name: "index_services_on_discarded_at"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sign_in_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "subscription_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.string "appoint_from_type", null: false
    t.uuid "appoint_from_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type", null: false
    t.uuid "appoint_for_id", null: false
    t.string "appoint_by_type", null: false
    t.uuid "appoint_by_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_subscription_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_subscription_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_subscription_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_subscription_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_subscription_appointments_on_discarded_at"
    t.index ["subscription_id"], name: "index_subscription_appointments_on_subscription_id"
  end

  create_table "subscription_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_group_id", null: false
    t.string "appoint_from_type", null: false
    t.uuid "appoint_from_id", null: false
    t.string "appoint_to_type", null: false
    t.uuid "appoint_to_id", null: false
    t.string "appoint_for_type", null: false
    t.uuid "appoint_for_id", null: false
    t.string "appoint_by_type", null: false
    t.uuid "appoint_by_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_subscription_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_subscription_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_subscription_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_subscription_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_subscription_group_appointments_on_discarded_at"
    t.index ["subscription_group_id"], name: "index_subscription_group_appointments_on_subscription_group_id"
  end

  create_table "subscription_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_subscription_groups_on_company_group_id"
    t.index ["company_id"], name: "index_subscription_groups_on_company_id"
    t.index ["discarded_at"], name: "index_subscription_groups_on_discarded_at"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_group_id", null: false
    t.uuid "company_group_id", null: false
    t.uuid "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_subscriptions_on_company_group_id"
    t.index ["company_id"], name: "index_subscriptions_on_company_id"
    t.index ["discarded_at"], name: "index_subscriptions_on_discarded_at"
    t.index ["subscription_group_id"], name: "index_subscriptions_on_subscription_group_id"
  end

  create_table "tag_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_tag_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_tag_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_tag_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_tag_appointments_on_appoint_to"
    t.index ["tag_id"], name: "index_tag_appointments_on_tag_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_tags_on_company_group_id"
  end

  create_table "task_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_task_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_task_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_task_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_task_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_task_appointments_on_discarded_at"
    t.index ["task_id"], name: "index_task_appointments_on_task_id"
  end

  create_table "task_group_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_by_type", "appoint_by_id"], name: "index_task_group_appointments_on_appoint_by"
    t.index ["appoint_for_type", "appoint_for_id"], name: "index_task_group_appointments_on_appoint_for"
    t.index ["appoint_from_type", "appoint_from_id"], name: "index_task_group_appointments_on_appoint_from"
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_task_group_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_task_group_appointments_on_discarded_at"
    t.index ["task_group_id"], name: "index_task_group_appointments_on_task_group_id"
  end

  create_table "task_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_task_groups_on_company_group_id"
    t.index ["company_id"], name: "index_task_groups_on_company_id"
    t.index ["discarded_at"], name: "index_task_groups_on_discarded_at"
  end

  create_table "tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_group_id", null: false
    t.uuid "company_id"
    t.uuid "task_group_id", null: false
    t.string "name"
    t.string "description"
    t.string "code"
    t.integer "currency"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_group_id"], name: "index_tasks_on_company_group_id"
    t.index ["company_id"], name: "index_tasks_on_company_id"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["task_group_id"], name: "index_tasks_on_task_group_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.string "provider"
    t.string "uid"
    t.uuid "parent_user_id"
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.string "phone_number"
    t.string "country_code"
    t.uuid "address_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["parent_user_id"], name: "index_users_on_parent_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answers", "questions"
  add_foreign_key "bookings", "companies"
  add_foreign_key "bookings", "company_groups"
  add_foreign_key "cart_appointments", "carts"
  add_foreign_key "cart_groups", "companies"
  add_foreign_key "cart_groups", "company_groups"
  add_foreign_key "carts", "cart_groups"
  add_foreign_key "carts", "companies"
  add_foreign_key "carts", "company_groups"
  add_foreign_key "companies", "companies", column: "parent_company_id"
  add_foreign_key "companies", "company_groups"
  add_foreign_key "company_groups", "users"
  add_foreign_key "customer_appointments", "customers"
  add_foreign_key "customer_group_appointments", "customer_groups"
  add_foreign_key "customer_groups", "companies"
  add_foreign_key "customer_groups", "company_groups"
  add_foreign_key "customers", "companies"
  add_foreign_key "customers", "company_groups"
  add_foreign_key "customers", "users"
  add_foreign_key "employee_appointments", "employees"
  add_foreign_key "employee_group_appointments", "employee_groups"
  add_foreign_key "employee_groups", "companies"
  add_foreign_key "employee_groups", "company_groups"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "company_groups"
  add_foreign_key "employees", "users"
  add_foreign_key "event_appointments", "events"
  add_foreign_key "event_group_appointments", "event_groups"
  add_foreign_key "event_groups", "companies"
  add_foreign_key "event_groups", "company_groups"
  add_foreign_key "events", "companies"
  add_foreign_key "events", "company_groups"
  add_foreign_key "events", "event_groups"
  add_foreign_key "exam_appointments", "exams"
  add_foreign_key "exam_groups", "companies"
  add_foreign_key "exam_groups", "company_groups"
  add_foreign_key "exams", "companies"
  add_foreign_key "exams", "company_groups"
  add_foreign_key "exams", "exam_groups"
  add_foreign_key "facilities", "companies"
  add_foreign_key "facilities", "company_groups"
  add_foreign_key "facility_appointments", "facilities"
  add_foreign_key "facility_group_appointments", "facility_groups"
  add_foreign_key "facility_groups", "companies"
  add_foreign_key "facility_groups", "company_groups"
  add_foreign_key "inventories", "companies"
  add_foreign_key "inventories", "company_groups"
  add_foreign_key "inventory_item_appointments", "inventory_items"
  add_foreign_key "inventory_items", "inventories"
  add_foreign_key "inventory_transaction_appointments", "inventory_transactions"
  add_foreign_key "inventory_transactions", "companies"
  add_foreign_key "inventory_transactions", "company_groups"
  add_foreign_key "invoices", "orders"
  add_foreign_key "notification_appointments", "notifications"
  add_foreign_key "notification_group_appointments", "notification_groups"
  add_foreign_key "notification_groups", "companies"
  add_foreign_key "notification_groups", "company_groups"
  add_foreign_key "notifications", "companies"
  add_foreign_key "notifications", "company_groups"
  add_foreign_key "notifications", "notification_groups"
  add_foreign_key "order_appointments", "orders"
  add_foreign_key "order_group_appointments", "order_groups"
  add_foreign_key "order_groups", "companies"
  add_foreign_key "order_groups", "company_groups"
  add_foreign_key "order_groups", "customers"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "company_groups"
  add_foreign_key "orders", "customers"
  add_foreign_key "payment_method_appointments", "companies"
  add_foreign_key "payment_method_appointments", "company_groups"
  add_foreign_key "payment_method_appointments", "payment_methods"
  add_foreign_key "payments", "invoices"
  add_foreign_key "period_appointments", "periods"
  add_foreign_key "periods", "companies"
  add_foreign_key "periods", "company_groups"
  add_foreign_key "policies", "companies"
  add_foreign_key "policies", "company_groups"
  add_foreign_key "policy_appointments", "policies"
  add_foreign_key "product_appointments", "products"
  add_foreign_key "product_group_appointments", "product_groups"
  add_foreign_key "product_groups", "companies"
  add_foreign_key "product_groups", "company_groups"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "company_groups"
  add_foreign_key "project_appointments", "projects"
  add_foreign_key "project_group_appointments", "project_groups"
  add_foreign_key "project_groups", "companies"
  add_foreign_key "project_groups", "company_groups"
  add_foreign_key "projects", "companies"
  add_foreign_key "projects", "company_groups"
  add_foreign_key "projects", "project_groups"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "companies"
  add_foreign_key "purchases", "company_groups"
  add_foreign_key "questions", "companies"
  add_foreign_key "questions", "company_groups"
  add_foreign_key "role_appointments", "roles"
  add_foreign_key "roles", "companies"
  add_foreign_key "roles", "company_groups"
  add_foreign_key "service_appointments", "services"
  add_foreign_key "service_group_appointments", "service_groups"
  add_foreign_key "service_groups", "companies"
  add_foreign_key "service_groups", "company_groups"
  add_foreign_key "services", "companies"
  add_foreign_key "services", "company_groups"
  add_foreign_key "sessions", "users"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "subscription_appointments", "subscriptions"
  add_foreign_key "subscription_group_appointments", "subscription_groups"
  add_foreign_key "subscription_groups", "companies"
  add_foreign_key "subscription_groups", "company_groups"
  add_foreign_key "subscriptions", "companies"
  add_foreign_key "subscriptions", "company_groups"
  add_foreign_key "subscriptions", "subscription_groups"
  add_foreign_key "tag_appointments", "tags"
  add_foreign_key "tags", "company_groups"
  add_foreign_key "task_appointments", "tasks"
  add_foreign_key "task_group_appointments", "task_groups"
  add_foreign_key "task_groups", "companies"
  add_foreign_key "task_groups", "company_groups"
  add_foreign_key "tasks", "companies"
  add_foreign_key "tasks", "company_groups"
  add_foreign_key "tasks", "task_groups"
  add_foreign_key "users", "addresses"
  add_foreign_key "users", "users", column: "parent_user_id"
end
