class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :document_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      t.string :title
      t.json :content
      t.text :body_markdown
      t.string :name
      t.string :description
      t.string :code

      1.upto(10) { |i| t.string "property_string_#{i}" }
      1.upto(20) { |i| t.integer "property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "property_boolean_#{i}" }
      1.upto(10)  { |i| t.datetime "property_datetime_#{i}" }

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
  end
end
