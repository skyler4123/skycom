class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :chat_conversation, null: false, foreign_key: true, type: :uuid
      t.references :chat_user, null: false, foreign_key: true, type: :uuid
      t.text :body

      t.timestamps
    end
    add_index :chat_messages, %i[chat_conversation_id created_at]
  end
end
