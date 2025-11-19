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

ActiveRecord::Schema[8.0].define(version: 2025_11_19_001325) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
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

  create_table "companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "parent_company_id"
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "ownership_type"
    t.integer "business_type"
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
    t.index ["discarded_at"], name: "index_companies_on_discarded_at"
    t.index ["parent_company_id"], name: "index_companies_on_parent_company_id"
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "company_id"
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
  end

  create_table "employee_group_appointments", force: :cascade do |t|
    t.bigint "employee_group_id", null: false
    t.string "appoint_to_type", null: false
    t.bigint "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_employee_group_appointments_on_appoint_to"
    t.index ["employee_group_id"], name: "index_employee_group_appointments_on_employee_group_id"
  end

  create_table "employee_groups", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employee_groups_on_company_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["discarded_at"], name: "index_employees_on_discarded_at"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "facilities", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_facilities_on_company_id"
    t.index ["discarded_at"], name: "index_facilities_on_discarded_at"
  end

  create_table "policies", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.string "resource"
    t.string "action"
    t.integer "status"
    t.integer "kind"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_policies_on_company_id"
    t.index ["discarded_at"], name: "index_policies_on_discarded_at"
  end

  create_table "policy_appointments", force: :cascade do |t|
    t.bigint "policy_id", null: false
    t.string "appoint_to_type", null: false
    t.bigint "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "kind"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_policy_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_policy_appointments_on_discarded_at"
    t.index ["policy_id"], name: "index_policy_appointments_on_policy_id"
  end

  create_table "product_brands", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_product_brands_on_discarded_at"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "product_brand_id"
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["product_brand_id"], name: "index_products_on_product_brand_id"
  end

  create_table "role_appointments", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.string "appoint_to_type", null: false
    t.bigint "appoint_to_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "kind"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_role_appointments_on_appoint_to"
    t.index ["discarded_at"], name: "index_role_appointments_on_discarded_at"
    t.index ["role_id"], name: "index_role_appointments_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "kind"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_roles_on_company_id"
    t.index ["discarded_at"], name: "index_roles_on_discarded_at"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.integer "status"
    t.integer "business_type"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_services_on_company_id"
    t.index ["discarded_at"], name: "index_services_on_discarded_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sign_in_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "tag_appointments", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.string "appoint_to_type", null: false
    t.bigint "appoint_to_id", null: false
    t.string "value"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appoint_to_type", "appoint_to_id"], name: "index_tag_appointments_on_appoint_to"
    t.index ["tag_id"], name: "index_tag_appointments_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_tags_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.string "provider"
    t.string "uid"
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.string "phone_number"
    t.string "country_code"
    t.bigint "address_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "companies", "companies", column: "parent_company_id"
  add_foreign_key "companies", "users"
  add_foreign_key "customers", "companies"
  add_foreign_key "employee_group_appointments", "employee_groups"
  add_foreign_key "employee_groups", "companies"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "users"
  add_foreign_key "facilities", "companies"
  add_foreign_key "policies", "companies"
  add_foreign_key "policy_appointments", "policies"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "product_brands"
  add_foreign_key "role_appointments", "roles"
  add_foreign_key "roles", "companies"
  add_foreign_key "services", "companies"
  add_foreign_key "sessions", "users"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "tag_appointments", "tags"
  add_foreign_key "tags", "companies"
  add_foreign_key "users", "addresses"
end
