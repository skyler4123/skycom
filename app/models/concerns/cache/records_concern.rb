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
    # Usage: Employee.cached_where(company_id: 'uuid', expires_in: 1.hour)
    def cached_where(**filters)
      expires_in = filters.delete(:expires_in) || 5.minutes

      relation = where(filters)
      sql_hash = Digest::SHA256.base64digest(relation.to_sql.squish).tr("+/", "-_").first(12)
      cache_key = "#{model_name.plural.underscore}/q#{sql_hash}"

      attributes_array = Rails.cache.fetch(cache_key, expires_in: expires_in) do
        relation.map(&:attributes)
      end

      return [] if attributes_array.blank?
      attributes_array.map { |attrs| instantiate(attrs) }
    end

    # Usage: User.cached_find(id, expires_in: 10.minutes)
    # Or: User.cached_find(id)
    def cached_find(id, **options)
      return nil if id.blank?

      expires_in = options.delete(:expires_in) || 5.minutes
      cache_key  = "#{model_name.plural}_#{id}"

      attributes = Rails.cache.fetch(cache_key, expires_in: expires_in) do
        find_by(id: id)&.attributes
      end

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
