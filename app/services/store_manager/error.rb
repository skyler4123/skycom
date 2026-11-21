# frozen_string_literal: true

# Domain error for the Store Manager console write paths. Controllers rescue
# it and return the standard { errors: [...] } contract.
module StoreManager
  class Error < StandardError; end
end
