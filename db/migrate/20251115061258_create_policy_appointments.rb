class CreatePolicyAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_appointments do |t|
      t.references :policy, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.integer :status
      t.integer :kind
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :policy_appointments, :discarded_at
  end
end
