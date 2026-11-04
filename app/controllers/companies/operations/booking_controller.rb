# frozen_string_literal: true

class Companies::Operations::BookingController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :booking
  end
end
