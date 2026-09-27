class CreateArticleGroupEmployeeAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :article_group_employee_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :article_group, null: false, foreign_key: { to_table: :article_groups }, type: :uuid
      t.references :employee, null: false, foreign_key: { to_table: :employees }, type: :uuid
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
    add_index :article_group_employee_appointments, [:company_id, :article_group_id, :employee_id], unique: true, name: "idx_article_group_employee_appointments_uniq"
  end
end
