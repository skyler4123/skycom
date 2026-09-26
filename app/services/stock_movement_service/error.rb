# frozen_string_literal: true

# Raised by StockMovementService::* when a stock movement cannot be applied
# (floor violation, invalid params, missing stock row resolution). Callers'
# transactions roll back everything (document + ledger + quantity); controllers
# rescue this and render 422 { errors: [...] }.
class StockMovementService::Error < StandardError; end
