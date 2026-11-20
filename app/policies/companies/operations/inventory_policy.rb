# frozen_string_literal: true

# InventoryPolicy — the Inventory console is read-only; its CSV export is the
# same read permission as the page itself.
class Companies::Operations::InventoryPolicy < Companies::Operations::BasePolicy
  def ledger?
    show?
  end
end
