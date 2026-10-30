# frozen_string_literal: true

# User::CacheConcern — Atomic purpose: cache invalidation hook for User records.
#
# Why it exists: User data is cached by client/session flows; updates must bump
# the cache key without running full validations.
# How it works: #refresh_cache touches the user, updating updated_at (and thus
# the cache version).
# Main associations: none directly.
module User::CacheConcern
  extend ActiveSupport::Concern

  included do
    def refresh_cache
      # .touch updates the updated_at timestamp to the current time
      # without triggering all model validations.
      self.touch
    end
  end
end
