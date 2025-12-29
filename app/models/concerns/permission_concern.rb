module PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (RBAC)
    # =========================================================================

    # 1. The Public Check
    # Uses the cached hash to return true/false instantly.
    def can?(action_name, resource_name)
      # Normalize inputs to match how they are stored in DB
      action   = action_name.to_s
      resource = resource_name.is_a?(Class) ? resource_name.name : resource_name.to_s

      # Look up resource in the hash.
      # Use safe navigation (&.) because the resource key might not exist.
      permissions[resource]&.include?(action) || false
    end

    # 2. The Cache Layer
    # Fetches from Redis/Memcached. Key changes automatically if Employee is updated.
    def permissions
      Rails.cache.fetch([ self, "permissions" ], expires_in: 30.minutes) do
        load_permissions_from_db
      end
    end

    # 3. The Database Logic
    # Returns: { 'Order' => ['create', 'read'], 'Product' => ['read'] }
    def load_permissions_from_db
      # Fetch tuples of [Resource, Action]
      pairs = roles.joins(:policies)
                  .distinct
                  .pluck("policies.resource", "policies.action")

      # This ensures Marshal.dump can serialize it for the cache.
      pairs.each_with_object({}) do |(resource, action), result|
        result[resource] ||= [] # Initialize array if key is missing
        result[resource] << action
      end
    end
  end
end
