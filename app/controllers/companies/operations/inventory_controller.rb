# frozen_string_literal: true

class Companies::Operations::InventoryController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :inventory
  end
end
