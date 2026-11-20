# frozen_string_literal: true

# Inventory::Error — business failure raised by the Inventory console services.
# Controllers rescue it into `422 { errors: [...] }` (docs/API_ERROR_FORMAT.md).
class Inventory::Error < StandardError; end
