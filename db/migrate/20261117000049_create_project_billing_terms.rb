class CreateProjectBillingTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :project_billing_terms, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :project, null: false, foreign_key: true, type: :uuid

      # --- Terms ---
      t.integer :billing_model, null: false, default: 2
      t.bigint  :rate_cents, null: false, default: 0
      t.bigint  :cap_cents
      t.integer :currency, default: 840
      t.integer :retainer_period_days

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :project_billing_terms, [ :company_id, :project_id ], unique: true
  end
end
