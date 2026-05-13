# app/models/concerns/cache/records_concern.rb
module Cache::RecordsConcern
  extend ActiveSupport::Concern

  included do
    # Hooks to keep the cache in sync with the database
    after_commit :write_attribute_cache, on: [ :create, :update ]
    after_commit :remove_attribute_cache, on: :destroy
  end

  # Class methods for fetching
  class_methods do
    # Usage: Employee.cached_where(company_id: 'uuid', status: 'active')
    def cached_where(**filters)
      # 1. Create the relation to generate the SQL
      relation = where(**filters)

      # 2. Generate a unique key based on the SQL
      sql_raw  = relation.to_sql.squish
      sql_hash = Digest::SHA256.base64digest(sql_raw).tr("+/", "-_").first(12)

      # Example Key: employees/queries/qR3V5X_xvZ2lj
      cache_key = "#{model_name.plural.underscore}/queries/q#{sql_hash}"

      # 3. Fetch the array of attribute hashes from Solid Cache
      attributes_array = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        # We execute the query and convert the result to an array of hashes
        relation.map(&:attributes)
      end

      return [] if attributes_array.blank?

      # 4. Turn the raw hashes back into actual model objects
      # .instantiate tells Rails the record is already persisted in the DB
      attributes_array.map { |attrs| instantiate(attrs) }
    end

    # Usage: @user = User.cached_find(params[:id])
    def cached_find(id)
      return nil if id.blank?

      cache_key = "#{model_name.plural}_#{id}"

      # Fetch the hash and re-hydrate into a new object
      attributes = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        # If it's a miss, hit the DB and return the attributes hash
        find_by(id: id)&.attributes
      end

      # Turn the hash back into a model instance (without hitting DB)
      # .instantiate is the "Senior Dev" way to create an object from
      # a hash while marking it as "persisted" (not a new record).
      instantiate(attributes) if attributes.present?
    end
  end

  # Instance methods for synchronization
  def write_attribute_cache
    cache_key = "#{self.class.model_name.plural}_#{id}"
    # We store only the attributes hash
    Rails.cache.write(cache_key, attributes)
  end

  def remove_attribute_cache
    cache_key = "#{self.class.model_name.plural}_#{id}"
    Rails.cache.delete(cache_key)
  end
end
