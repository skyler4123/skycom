# frozen_string_literal: true

# Adds the store-floor fulfilment state to orders, separate from the payment
# workflow_status:
#
# - fulfillment_channel: how the goods leave the store.
# - fulfillment_status: unfulfilled → ready → handed_over.
# - handed_over_at: when the customer/driver took the goods, so a historical
#   day can be reconstructed without today's handovers rewriting it.
#
# Existing rows are backfilled once from business_type. New order forms/POS own
# the field afterwards.
class AddFulfillmentFieldsToOrders < ActiveRecord::Migration[8.0]
  def up
    add_column :orders, :fulfillment_channel, :integer, default: 0, null: false
    add_column :orders, :fulfillment_status, :integer, default: 0, null: false
    add_column :orders, :handed_over_at, :datetime

    add_index :orders, [ :branch_id, :fulfillment_channel ]
    add_index :orders, [ :branch_id, :handed_over_at ]

    execute <<~SQL.squish
      UPDATE orders SET fulfillment_channel = 2 WHERE business_type = 0
    SQL
    execute <<~SQL.squish
      UPDATE orders SET fulfillment_channel = 3 WHERE business_type = 2
    SQL
    execute <<~SQL.squish
      UPDATE orders
      SET fulfillment_status = 2,
          handed_over_at = COALESCE(updated_at, created_at)
      WHERE workflow_status = 4
    SQL
    execute <<~SQL.squish
      UPDATE orders
      SET fulfillment_status = 2,
          handed_over_at = COALESCE(updated_at, created_at)
      WHERE business_type = 1 AND workflow_status IN (4, 5)
    SQL
    execute <<~SQL.squish
      UPDATE orders o
      SET code = 'ORD-' || upper(right(replace(o.id::text, '-', ''), 8))
      WHERE o.code IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM orders existing
          WHERE existing.code = 'ORD-' || upper(right(replace(o.id::text, '-', ''), 8))
        )
    SQL
    execute <<~SQL.squish
      UPDATE orders
      SET code = 'ORD-' || upper(replace(id::text, '-', ''))
      WHERE code IS NULL
    SQL
  end

  def down
    remove_index :orders, [ :branch_id, :fulfillment_channel ]
    remove_index :orders, [ :branch_id, :handed_over_at ]
    remove_column :orders, :handed_over_at
    remove_column :orders, :fulfillment_status
    remove_column :orders, :fulfillment_channel
  end
end
