# config/initializers/cache.rb
module Rails
  class << self
    # Shared Redis pub/sub channel for cache invalidation messages.
    # Used by sync_cache to broadcast write/delete events to all instances.
    SYNC_CACHE_CHANNEL = "sync_cache:invalidation".freeze

    # Per-server Solid Cache (SQLite). Fast local reads, no network cost.
    # Used directly by AnalyticsController, BillingController, and PermissionConcern
    # for cached data that doesn't need cross-instance synchronization.
    def local_cache
      @local_cache ||= ActiveSupport::Cache.lookup_store(:solid_cache_store)
    end

    # Cross-cluster Redis cache. Used where atomic distributed state is required
    # (e.g., order processing stock counters, rate limits).
    def global_cache
      @global_cache ||= begin
        redis_config = Rails.application.config_for("redis/shared").symbolize_keys
        ActiveSupport::Cache.lookup_store(:redis_cache_store, redis_config)
      end
    end

    # Wraps local_cache with Redis pub/sub invalidation.
    # Read path: local_cache only — no Redis call per request.
    # Write/delete path: local_cache + broadcasts invalidation to Redis.
    # Other instances receive the message and evict the stale key from
    # their own local_cache, keeping all instances in sync without
    # per-request global reads.
    def sync_cache
      @sync_cache ||= SyncCache.new
    end
  end
end

# Local cache wrapper that broadcasts write/delete events via Redis pub/sub.
# Reads hit the per-server SQLite cache directly (fast, no network).
# Mutations also publish to a shared Redis channel so all server instances
# can evict the stale key from their own local_cache.
class SyncCache
  CHANNEL = "sync_cache:invalidation".freeze

  # Reads from local_cache only. Returns cached value or evaluates block,
  # caching the result. No Redis call.
  def fetch(key, expires_in: nil, &block)
    Rails.local_cache.fetch(key, expires_in: expires_in, &block)
  end

  # Direct local_cache read. No Redis call.
  def read(key)
    Rails.local_cache.read(key)
  end

  # Writes to local_cache and, when sync: true (default), publishes
  # an invalidation message so other instances evict their stale copy.
  def write(key, value, expires_in: nil, sync: true)
    Rails.local_cache.write(key, value, expires_in: expires_in)
    publish_invalidation("write", key) if sync
  end

  # Deletes from local_cache and, when sync: true (default), publishes
  # an invalidation message so other instances do the same.
  def delete(key, sync: true)
    Rails.local_cache.delete(key)
    publish_invalidation("delete", key) if sync
  end

  # Called by the background listener when an invalidation message arrives
  # from another instance. Evicts the stale key from local_cache.
  def handle_invalidation(payload)
    data = JSON.parse(payload) rescue nil
    return unless data && data["key"]

    Rails.local_cache.delete(data["key"])
  rescue => e
    Rails.logger.error("[SyncCache] Invalidation handling error: #{e.message}")
  end

  private

  # Publishes a write/delete event to the shared Redis channel.
  # All subscribed instances (including the publisher, if subscribed)
  # receive the message and evict the key from their local_cache.
  def publish_invalidation(action, key)
    payload = { action: action, key: key }.to_json
    Kredis.redis.publish(CHANNEL, payload)
  rescue => e
    Rails.logger.error("[SyncCache] Failed to publish invalidation: #{e.message}")
  end
end

# Background listener thread. Subscribes to the Redis invalidation channel
# and evicts stale entries from local_cache when another instance broadcasts
# a write/delete. Runs only on server processes (Puma), not during tests
# or rake tasks.
Rails.application.config.after_initialize do
  # Ensure we only start the subscriber in web server processes (Puma/Unicorn/Pitchfork)
  # and explicitly bypass for CLI tasks (rake, db:seed, rails console, rspec)
  is_server = defined?(Rails::Server) || 
              $PROGRAM_NAME.include?("puma") || 
              $PROGRAM_NAME.include?("bin/rails server")

  is_cli_or_test = Rails.env.test? || 
                   defined?(Rails::Console) || 
                   File.basename($PROGRAM_NAME) == "rake"

  if is_server && !is_cli_or_test
    Thread.new do
      # CRITICAL: Use a dedicated Redis connection for Pub/Sub!
      # Reusing Kredis.redis will hijack the shared app connection pool.
      redis_sub = Kredis.redis.dup

      loop do
        redis_sub.subscribe(SyncCache::CHANNEL) do |on|
          on.message do |_channel, message|
            Rails.sync_cache.handle_invalidation(message)
          end
        end
      rescue => e
        Rails.logger.error("[SyncCache Listener] Connection lost: #{e.message}")
        sleep 5
      end
    end
  end
end
