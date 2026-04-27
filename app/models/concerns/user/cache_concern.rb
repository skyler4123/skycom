# app/models/concerns/user/cache_concern.rb

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
