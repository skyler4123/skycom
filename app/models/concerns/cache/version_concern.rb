module Cache::VersionConcern
  extend ActiveSupport::Concern

  included do
    # Ensure the model has the required column
    # add_column :users, :cache_versions, :jsonb, default: {}
  end

  # Generates a cache key for a specific scope
  # Usage: @user.cache_key_for(:profile)
  # Result: "users/123/profile-5"
  def cache_key_for(scope)
    # Get the version for this scope, defaulting to 1 if never set
    version = (self.cache_versions[scope.to_s] || 1)
    
    # We combine model name, id, scope, and the specific version
    "#{model_name.cache_key}/#{id}/#{scope}-#{version}"
  end

  # Bumps the version for one or more scopes
  # Usage: @user.bump_cache_version(:profile, :settings)
  def bump_cache_version(*scopes)
    updates = {}
    
    scopes.each do |scope|
      current_ver = (self.cache_versions[scope.to_s] || 0).to_i
      updates[scope.to_s] = current_ver + 1
    end

    # Merge updates into the existing hash
    # We use update_column to avoid triggering 'updated_at' 
    # and causing a "Russian Doll" invalidation of everything else!
    new_versions = self.cache_versions.merge(updates)
    update_column(:cache_versions, new_versions)
  end
end



# class User < ApplicationRecord
#   include Cache::VersionConcern

#   # Use callbacks to intelligently bump keys
#   before_save :update_granular_keys

#   private

#   def update_granular_keys
#     # If I change my bio, only the profile cache invalidates
#     if bio_changed? || avatar_changed?
#       bump_cache_version(:profile)
#     end

#     # If I change my settings, only settings cache invalidates
#     if notifications_changed?
#       bump_cache_version(:settings)
#     end
    
#     # Note: If 'last_login_at' changes, we do NOTHING here.
#     # This effectively saves the other caches from breaking.
#   end
# end

# # In a Service, Controller, or Model method
# def calculate_lifetime_value
#   # This generates a key like: "users/123/financials-5"
#   # It ignores updates to the user's name/bio/settings!
#   Rails.cache.fetch(cache_key_for(:financials), expires_in: 1.week) do
#     # Heavy SQL query inside the block
#     orders.completed.sum(:total_price)
#   end
# end

# # app/models/user.rb
# class User < ApplicationRecord
#   include Cache::VersionConcern

#   # The method that uses the cache
#   def total_post_views
#     # Key: "users/123/stats-10"
#     Rails.cache.fetch(cache_key_for(:stats)) do
#       posts.sum(:views_count) # The heavy SQL
#     end
#   end
# end
# # app/models/post.rb
# class Post < ApplicationRecord
#   belongs_to :user

#   # Instead of standard 'touch: true' (which bumps everything),
#   # we use a custom callback.
#   after_commit :bump_user_stats_cache

#   private

#   def bump_user_stats_cache
#     # If the views count changed, tell the User model to bump the :stats version
#     if saved_change_to_views_count? || id_previously_changed?
#       user.bump_cache_version(:stats) 
#     end
#   end
# end