# frozen_string_literal: true

# CreatedAtDefaultOrderingConcern — Atomic purpose: makes created_at the
# implicit ordering column for every model.
#
# Why it exists: `.first`/`.last` should follow creation order consistently
# instead of the database's arbitrary order.
# How it works: sets self.implicit_order_column = "created_at" at include time;
# ApplicationRecord includes it once for all models.
# Main associations: none directly.
module CreatedAtDefaultOrderingConcern
  extend ActiveSupport::Concern

  included do
    # Sets the default column for methods like .first and .last
    self.implicit_order_column = "created_at"
  end
end
