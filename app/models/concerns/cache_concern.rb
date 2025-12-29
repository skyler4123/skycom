# Provides instance methods for attaching and managing Tags on a resource
module CacheConcern
  extend ActiveSupport::Concern

  included do
    # Generates a consistent cache key, e.g., "session/123" or "user/99"
    def self.cache_key_for(id)
      "#{name.underscore}/#{id}"
    end
  end
end
