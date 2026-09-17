# frozen_string_literal: true

# Chatwoot namespace root. Holds the shared error hierarchy so referencing
# any Chatwoot constant loads it before the service/client classes. The
# Chatwoot database is the second source of truth for chat data — see
# docs/CHATWOOT.md.
module Chatwoot
  class Error < StandardError; end

  class NotFoundError < Error; end

  class UnauthorizedError < Error; end

  class ConnectionError < Error; end
end
