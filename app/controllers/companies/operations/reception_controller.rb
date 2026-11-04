# frozen_string_literal: true

class Companies::Operations::ReceptionController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :reception
  end
end
