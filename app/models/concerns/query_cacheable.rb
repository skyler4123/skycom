# app/models/concerns/query_cacheable.rb
module QueryCacheable
  extend ActiveSupport::Concern

  included do
    const_get(:ActiveRecord_Relation).include RelationMethods
  end

  module RelationMethods
    def cached_query(expires_in: 1.minutes)
      # 1. Automatically detect the company from the global state
      company = Company.first
      raise "Current.company is missing!" unless company

      # 3. Generate the key unique to this Company + Version + SQL
      sql_hash = Digest::MD5.hexdigest(self.to_sql)
      cache_key = "c_#{company.id.to_s[0..7]}/q_#{sql_hash}"
      puts cache_key
      # 4. Fetch IDs from Solid Cache (SQLite)
      id_list = Rails.cache.fetch(cache_key, expires_in: expires_in) do
        # ActiveRecord::Base.connected_to(role: :reading) { self.pluck(:id) }
        # self.pluck(:id)
        with_reading_connection { self.pluck(:id) }
      end

      return self.model.none if id_list.empty?

      # 5. Hydrate from Postgres Replica
      # ActiveRecord::Base.connected_to(role: :reading) { self.model.where(id: id_list) }
      # self.model.where(id: id_list)
      with_reading_connection { self.model.where(id: id_list) }
    end

    def clear_cached_query
      company = Company.first
      raise "Current.company is missing!" unless company
      sql_hash = Digest::SHA256.hexdigest(self.to_sql)
      cache_key = "c_#{company.id}/q_#{sql_hash}"
      Rails.cache.delete(cache_key)
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
