class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :user_agent
      t.string :ip_address
      t.string :single_access_token

      t.timestamps
    end
    add_index :sessions, :single_access_token, unique: true
  end
end
