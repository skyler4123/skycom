# frozen_string_literal: true

# Every Inventory console action runs behind the same operation-access gate:
# showing the console and finishing a receive/transfer/export/adjust/reorder/
# count are one workflow, so they all require Operation read.
class Companies::Operations::InventoryPolicy < Companies::Operations::BasePolicy
  INVENTORY_ACTIONS = %i[
    ledger export
    create_receipt post_receipt
    create_transfer receive_transfer
    create_export create_adjustment create_reorder
    start_count show_count update_count submit_count
  ].freeze

  INVENTORY_ACTIONS.each do |action|
    define_method("#{action}?") { show? }
  end
end
