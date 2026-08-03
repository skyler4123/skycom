# app/models/concerns/cache/records_concern.rb
module Cache::RecordsConcern
  extend ActiveSupport::Concern

  # Default TTL for model attribute caching. Used by cached_find /
  # cached_where class methods when no explicit expires_in is provided.
  DEFAULT_CACHE_EXPIRY = 5.minutes

  included do
    after_commit :write_attribute_cache, on: [ :create, :update ]
    after_commit :remove_attribute_cache, on: :destroy
  end

  class_methods do
    def cached_where(**filters)
      expires_in = filters.delete(:expires_in) || DEFAULT_CACHE_EXPIRY

      relation = where(filters)
      sql_hash = Digest::SHA256.base64digest(relation.to_sql.squish).tr("+/", "-_").first(12)
      cache_key = "#{model_name.plural.underscore}/q#{sql_hash}"

      # Switched to sync_cache
      attributes_array = Rails.sync_cache.fetch(cache_key, expires_in: expires_in) do
        relation.map(&:attributes)
      end

      return [] if attributes_array.blank?
      attributes_array.map do |attrs|
        normalize_enum_attributes!(attrs)
        instantiate(attrs)
      end
    end

    def cached_find(id, **options)
      return nil if id.blank?

      expires_in = options.delete(:expires_in) || DEFAULT_CACHE_EXPIRY
      cache_key  = "#{model_name.plural}_#{id}"

      # Switched to sync_cache
      attributes = Rails.sync_cache.fetch(cache_key, expires_in: expires_in) do
        find_by(id: id)&.attributes
      end

      return nil if attributes.blank?

      normalize_enum_attributes!(attributes)
      instantiate(attributes)
    end

    private

    def normalize_enum_attributes!(attrs)
      defined_enums.each do |enum_name, mapping|
        value = attrs[enum_name]
        if value.is_a?(String) && mapping.key?(value)
          attrs[enum_name] = mapping[value]
        end
      end
    end
  end

  # Instance methods trigger cluster-wide invalidation via sync_cache
  def write_attribute_cache
    cache_key = "#{self.class.model_name.plural}_#{id}"
    Rails.sync_cache.write(cache_key, attributes)
  end

  def remove_attribute_cache
    cache_key = "#{self.class.model_name.plural}_#{id}"
    Rails.sync_cache.delete(cache_key)
  end
end
