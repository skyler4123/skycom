# frozen_string_literal: true

module Events
  # Raised when a stock hold fails under strict_stock_hold so the controller
  # rolls the whole save back (422, nothing persisted).
  class StrictHoldError < StandardError; end
end
