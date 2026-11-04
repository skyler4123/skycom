# frozen_string_literal: true

class Companies::Operations::HousekeepingController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :housekeeping
  end
end
