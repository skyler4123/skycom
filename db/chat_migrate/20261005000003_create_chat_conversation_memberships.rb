class CreateChatConversationMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_conversation_memberships, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :chat_conversation, null: false, foreign_key: true, type: :uuid
      t.references :chat_user, null: false, foreign_key: true, type: :uuid
      t.datetime :joined_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end
    add_index :chat_conversation_memberships, %i[chat_conversation_id chat_user_id],
      unique: true, name: "idx_chat_memberships_on_conversation_and_user"
  end
end
