# app/models/concerns/query_cacheable.rb
module QueryCacheable
  extend ActiveSupport::Concern

  included do
    const_get(:ActiveRecord_Relation).include RelationMethods
  end

  module RelationMethods
    # Set Current.company: Current.company_id = Company.first.id
    def cached_query(expires_in: 24.hours)
      # 1. Automatically detect the company from the global state
      company ||= Current.company
      raise "Current.company is missing!" unless company

      resource_name = self.model.name.underscore.pluralize
      model_cached_version_number = Current.cached_version["#{resource_name}_cached_version"]

      # 3. Generate the key unique to this Company + Version + SQL
      sql_hash = Digest::MD5.hexdigest(self.to_sql)
      cache_key = "c#{company.id.to_s[0..7]}/#{resource_name}/v#{model_cached_version_number}/q#{sql_hash}"
      puts cache_key
      # 4. Fetch IDs from Solid Cache (SQLite)
      id_list = Rails.cache.fetch(cache_key, expires_in: expires_in) do
        with_reading_connection { self.pluck(:id) }
      end

      return self.model.none if id_list.empty?

      # 5. Hydrate from Postgres Replica
      with_reading_connection { self.model.where(id: id_list) }
    end

    # Define a helper to handle the connection switch safely
    def with_reading_connection(&block)
      if ActiveRecord::Base.connection_handler.connection_pool_names.include?("reading")
        ActiveRecord::Base.connected_to(role: :reading, &block)
      else
        # Fallback for Local/Dev environment
        yield
      end
    end
  end
end
