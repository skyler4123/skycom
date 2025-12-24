module CacheableConcern
  extend ActiveSupport::Concern

  included do
    after_commit :invalidate_specific_cache
  end

  # ------------------------------------------------------------------------
  # 1. Class Methods: For finding records (Eager Loading)
  # ------------------------------------------------------------------------
  class_methods do
    def find_cached(id, includes: nil)
      return nil if id.blank?

      # Create a unique key based on the ID *and* what we are including
      key = generate_cache_key(id, includes)

      Rails.cache.fetch(key, expires_in: 24.hours) do
        query = where(id: id)
        query = query.includes(includes) if includes.present?
        query.first
      end
    end

    def generate_cache_key(id, includes)
      base = "#{model_name.cache_key}/#{id}"
      return base if includes.blank?

      # Append includes to the key so "Session+User" is stored differently than just "Session"
      # e.g., "sessions/123:inc:user"
      "#{base}:inc:#{includes.to_s.gsub(/[^a-z0-9]/i, '_')}"
    end
  end

  # ------------------------------------------------------------------------
  # 2. Instance Methods: For accessing associations (Collection Caching)
  # ------------------------------------------------------------------------
  def cached(relation_name)
    # This automatically uses the object's 'updated_at' timestamp (from touch: true)
    # If the User updates, this cache key changes automatically.
    Rails.cache.fetch([self, relation_name], expires_in: 12.hours) do
      public_send(relation_name).to_a
    end
  end

  private

  def invalidate_specific_cache
    # IMPORTANT: We must clear ALL variations of this ID (with or without includes).
    # 'delete_matched' works great with Redis. 
    # If you use Memcached, it is safer to stick to one consistent 'includes' pattern per model.
    Rails.cache.delete_matched("#{self.class.model_name.cache_key}/#{id}*")
  end
end
