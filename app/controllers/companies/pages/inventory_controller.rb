# frozen_string_literal: true

class Companies::Pages::InventoryController < Companies::Pages::BaseController
  private

  def expected_page_type
    :inventory
  end
end
