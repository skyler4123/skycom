class CreateChatConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_conversations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string :title
      # Creator pointer. Plain uuid column (same-DB but no hard FK — creator may be re-mirrored).
      t.uuid :created_by_chat_user_id, index: true

      t.timestamps
    end
  end
end
