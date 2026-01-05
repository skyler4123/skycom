module CreatedAtDefaultOrderingConcern
  extend ActiveSupport::Concern

  included do
    # Sets the default column for methods like .first and .last
    self.implicit_order_column = "created_at"
  end
end