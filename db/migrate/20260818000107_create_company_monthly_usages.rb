# frozen_string_literal: true

class CreateCompanyMonthlyUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :company_monthly_usages, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.date :usage_month, null: false

      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :company_monthly_usages, [ :company_id, :usage_month ], unique: true
  end
end
