# frozen_string_literal: true

class CreateTaxConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_configs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.uuid :company_id, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :company_id, unique: true
    end

    add_foreign_key :tax_configs, :companies
  end
end
