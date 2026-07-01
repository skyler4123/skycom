# config/initializers/local_and_global_cache.rb

module Rails
  class << self
    # Local Cache: Uses Solid Cache pointing to the local SQLite database.
    # This aligns with the default Rails.cache configuration.
    def local_cache
      @local_cache ||= ActiveSupport::Cache.lookup_store(:solid_cache_store)
    end

    # Global Cache: Uses Redis so all servers can share the same state
    # when scaling out to a multi-server cluster.
    # Configuration is loaded dynamically from config/redis/shared.yml.
    def global_cache
      @global_cache ||= begin
        redis_config = Rails.application.config_for("redis/shared").symbolize_keys
        ActiveSupport::Cache.lookup_store(:redis_cache_store, redis_config)
      end
    end

    # =========================================================================
    # PLACEHOLDERS FOR FUTURE SCALING
    # =========================================================================

    # Global Session Cache: Dedicated store for user sessions.
    # Currently routes to global_cache, but can be split into its own Redis
    # cluster or Memcached instance in the future to handle high write loads.
    def global_session_cache
      @global_session_cache ||= global_cache
    end

    # Object/Identity Cache: For caching ActiveRecord models (e.g., IdentityCache gem).
    # Currently uses local_cache (Solid Cache), but can be pointed to a fast,
    # centralized Redis/Memcached cluster later if DB load spikes.
    def identity_cache
      @identity_cache ||= local_cache
    end

    # HTTP/Fragment Cache: For view fragments or API response caching.
    # Currently defaults to local_cache, allowing you to isolate
    # heavy UI rendering cache from business logic cache later.
    def http_cache
      @http_cache ||= local_cache
    end
  end
end
