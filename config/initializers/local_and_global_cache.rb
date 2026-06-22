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
  end
end
