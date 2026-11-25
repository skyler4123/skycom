# frozen_string_literal: true

class AddTaxSnapshotsToOrderLines < ActiveRecord::Migration[8.1]
  def change
    %i[order_product_appointments order_service_appointments].each do |table|
      add_reference table, :tax_code, type: :uuid, null: true, foreign_key: true
      add_column table, :tax_name, :string
      add_column table, :tax_rate_bp, :integer, null: false, default: 0
      add_column table, :tax_inclusive, :boolean, null: false, default: false
      add_column table, :taxable_cents, :bigint, null: false, default: 0
      add_column table, :tax_cents, :bigint, null: false, default: 0
    end
  end
end
