# frozen_string_literal: true

class Companies::Operations::StoreManagerController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :store_manager
  end
end
