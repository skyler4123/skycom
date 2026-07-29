# config/initializers/multi_cache.rb

module Rails
  class << self
    # Local Cache: Uses Solid Cache pointing to the local SQLite database.
    def local_cache
      @local_cache ||= ActiveSupport::Cache.lookup_store(:solid_cache_store)
    end

    # Global Cache: Uses Redis shared across instances.
    def global_cache
      @global_cache ||= begin
        redis_config = Rails.application.config_for("redis/shared").symbolize_keys
        ActiveSupport::Cache.lookup_store(:redis_cache_store, redis_config)
      end
    end

    # L1 (Local SQLite) + L2 (Redis) combined with auto Pub/Sub invalidation
    def hybrid_cache
      @hybrid_cache ||= Module.new do
        const_set(:CHANNEL, "cache_sync_events".freeze)

        class << self
          # Read L1 -> Read L2 -> Fallback Block
          def fetch(key, options = {}, &block)
            # 1. Read from local SQLite (L1)
            value = Rails.local_cache.read(key, options)
            return value unless value.nil?

            # 2. Read from global Redis (L2)
            value = Rails.global_cache.read(key, options)
            if value.present?
              Rails.local_cache.write(key, value, options)
              return value
            end

            # 3. Cache Miss: Execute DB query block and write to both
            return block.call unless block_given?

            value = block.call
            write(key, value, options) if value.present?
            value
          end

          def read(key, options = {})
            value = Rails.local_cache.read(key, options)
            return value unless value.nil?

            value = Rails.global_cache.read(key, options)
            Rails.local_cache.write(key, value, options) if value.present?
            value
          end

          def write(key, value, options = {})
            Rails.local_cache.write(key, value, options)
            Rails.global_cache.write(key, value, options)

            publish_invalidation("write", key) if options.fetch(:sync, true)
            true
          end

          def delete(key, options = {})
            Rails.local_cache.delete(key, options)
            Rails.global_cache.delete(key, options)

            publish_invalidation("delete", key) if options.fetch(:sync, true)
            true
          end

          private

          def publish_invalidation(action, key)
            redis_or_pool = Rails.global_cache.redis
            payload = { action: action, key: key, sender_id: process_id }.to_json

            # Handle ConnectionPool vs Direct Redis Client
            if redis_or_pool.respond_to?(:with)
              redis_or_pool.with { |conn| conn.publish(self::CHANNEL, payload) }
            else
              redis_or_pool.publish(self::CHANNEL, payload)
            end
          rescue StandardError => e
            Rails.logger.error("[HybridCache] Invalidation Publish Failed: #{e.message}")
          end

          def process_id
            @process_id ||= "#{Socket.gethostname}-#{Process.pid}"
          end
        end
      end
    end

    # =========================================================================
    # PLACEHOLDERS FOR FUTURE SCALING
    # =========================================================================

    def global_session_cache
      @global_session_cache ||= global_cache
    end

    def identity_cache
      @identity_cache ||= local_cache
    end

    def http_cache
      @http_cache ||= local_cache
    end
  end
end


# =============================================================================
# CACHE SYNC LISTENER (Pub/Sub Subscriber)
# =============================================================================

module CacheSync
  def self.start_listener!
    return if @started
    @started = true

    Thread.new do
      process_id = "#{Socket.gethostname}-#{Process.pid}"
      redis_config = Rails.application.config_for("redis/shared").symbolize_keys

      loop do
        begin
          redis_subscriber = Redis.new(redis_config)

          redis_subscriber.subscribe(Rails.hybrid_cache::CHANNEL) do |on|
            on.message do |_channel, message|
              data = JSON.parse(message) rescue next
              next if data["sender_id"] == process_id

              if data["action"] == "write" || data["action"] == "delete"
                # Evicts key from this process's local SQLite cache
                Rails.local_cache.delete(data["key"])
              end
            end
          end
        rescue StandardError => e
          Rails.logger.warn("[CacheSync] Subscription disconnected: #{e.message}. Reconnecting in 3s...")
          sleep 3
        end
      end
    end
  end
end

Rails.application.config.after_initialize do
  next if defined?(Rails::Console) || File.basename($PROGRAM_NAME) == "rake"

  if defined?(Puma) && Puma.respond_to?(:cli)
    Puma.hooks[:on_worker_boot] << proc { CacheSync.start_listener! }
  else
    CacheSync.start_listener!
  end
end