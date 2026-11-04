# frozen_string_literal: true

class Companies::Operations::KitchenController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :kitchen
  end
end
