class CreateChatUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_users, id: :uuid, default: -> { "uuidv7()" } do |t|
      # Bridge to primary-DB User. Plain uuid column — cross-DB foreign keys are impossible.
      t.uuid :user_id, null: false, index: { unique: true }
      t.string :display_name, null: false
      t.string :email, null: false, index: true
      t.string :avatar_url

      t.timestamps
    end
  end
end
