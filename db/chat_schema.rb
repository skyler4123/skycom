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

ActiveRecord::Schema[8.1].define(version: 2026_10_05_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_conversation_memberships", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "chat_conversation_id", null: false
    t.uuid "chat_user_id", null: false
    t.datetime "joined_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_conversation_id", "chat_user_id"], name: "idx_chat_memberships_on_conversation_and_user", unique: true
    t.index ["chat_conversation_id"], name: "index_chat_conversation_memberships_on_chat_conversation_id"
    t.index ["chat_user_id"], name: "index_chat_conversation_memberships_on_chat_user_id"
  end

  create_table "chat_conversations", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "created_by_chat_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_chat_user_id"], name: "index_chat_conversations_on_created_by_chat_user_id"
  end

  create_table "chat_messages", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "chat_conversation_id", null: false
    t.uuid "chat_user_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_conversation_id", "created_at"], name: "index_chat_messages_on_chat_conversation_id_and_created_at"
    t.index ["chat_conversation_id"], name: "index_chat_messages_on_chat_conversation_id"
    t.index ["chat_user_id"], name: "index_chat_messages_on_chat_user_id"
  end

  create_table "chat_users", id: :uuid, default: -> { "uuidv7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_chat_users_on_email"
    t.index ["user_id"], name: "index_chat_users_on_user_id", unique: true
  end

  add_foreign_key "chat_conversation_memberships", "chat_conversations"
  add_foreign_key "chat_conversation_memberships", "chat_users"
  add_foreign_key "chat_messages", "chat_conversations"
  add_foreign_key "chat_messages", "chat_users"
end
