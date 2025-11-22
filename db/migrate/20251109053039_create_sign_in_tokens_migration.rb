class CreateSignInTokensMigration < ActiveRecord::Migration[8.0]
  def change
    create_table :sign_in_tokens, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
    end
  end
end
