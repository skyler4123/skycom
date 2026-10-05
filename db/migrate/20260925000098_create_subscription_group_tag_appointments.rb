class CreateSubscriptionGroupTagAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_group_tag_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :subscription_group, null: false, foreign_key: { to_table: :subscription_groups }, type: :uuid
      t.references :tag, null: false, foreign_key: { to_table: :tags }, type: :uuid
      t.string :value
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :subscription_group_tag_appointments, [ :company_id, :subscription_group_id, :tag_id ], unique: true, name: "idx_subscription_group_tag_appointments_uniq"
  end
end
