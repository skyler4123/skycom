class CreatePolicyAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_appointments, id: :uuid do |t|
      t.references :policy, null: false, foreign_key: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :policy_appointments, :discarded_at
  end
end
