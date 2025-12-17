Rails.configuration.identity_cache_store = :solid_cache_store, {
  expires_in: 1.minutes.to_i, # in case of network errors when sending a cache invalidation
  failover: false, # avoids more cache consistency issues
}

IdentityCache.cache_backend = ActiveSupport::Cache.lookup_store(*Rails.configuration.identity_cache_store)