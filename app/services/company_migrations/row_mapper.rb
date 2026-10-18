# frozen_string_literal: true

# Maps one CSV row into model attributes for a single config target:
#
#   CompanyMigrations::RowMapper.new(target:, company:).map(row)
#   # => { attrs: Hash, errors: [String] }
#
# attrs are string-keyed and exclude caller-owned keys (company_id,
# category_id, property_mapping_id — the engine adds those). Semantics:
# defaults seed attrs; a mapped column overrides only when its CSV value is
# non-blank; lookups resolve foreign keys by [company_id, external_id] with a
# per-mapper cache (one instance is reused across all rows of one target).
module CompanyMigrations
  class RowMapper
    BOOLEAN_TRUE_VALUES = %w[1 true yes y on].freeze

    def initialize(target:, company:)
      @target = target.is_a?(Hash) ? target : {}
      @company = company
      @model = @target["resource"].to_s.classify.safe_constantize
      @lookup_cache = {}
    end

    def map(row)
      attrs = {}
      metadata = {}
      errors = []

      apply_defaults(attrs, metadata)

      (@target["columns"] || {}).each do |source_column, mapping|
        next unless mapping.is_a?(Hash) && mapping["target"].present?

        target = mapping["target"]
        raw_value = row[source_column]
        next if raw_value.blank?

        if target.start_with?(Config::METADATA_PREFIX)
          metadata[target.delete_prefix(Config::METADATA_PREFIX)] = raw_value.to_s
          next
        end

        value, error = mapping["lookup"].present? ? lookup_value(mapping["lookup"], raw_value) : coerce(target, raw_value)

        if error
          errors << error
        else
          attrs[target] = value
        end
      end

      attrs["metadata"] = metadata if metadata.any?
      { attrs: attrs, errors: errors }
    end

    private

    def apply_defaults(attrs, metadata)
      (@target["defaults"] || {}).each do |target, value|
        if target.start_with?(Config::METADATA_PREFIX)
          metadata[target.delete_prefix(Config::METADATA_PREFIX)] = value
        else
          attrs[target] = value
        end
      end
    end

    def coerce(target, raw_value)
      value = raw_value.to_s

      case column_type(target)
      when :integer
        integer_value = Integer(value.strip, exception: false)
        integer_value.nil? ? [ nil, cannot_parse(target, raw_value) ] : [ integer_value, nil ]
      when :decimal
        decimal_value = BigDecimal(value.strip, exception: false)
        decimal_value.nil? ? [ nil, cannot_parse(target, raw_value) ] : [ decimal_value, nil ]
      when :boolean
        [ BOOLEAN_TRUE_VALUES.include?(value.strip.downcase), nil ]
      when :datetime, :date
        time_value = begin
          Time.zone.parse(value)
        rescue ArgumentError
          nil
        end
        time_value.nil? ? [ nil, cannot_parse(target, raw_value) ] : [ time_value, nil ]
      else
        [ value, nil ]
      end
    end

    def lookup_value(lookup, raw_value)
      key = [ lookup["resource"], raw_value.to_s ]
      return @lookup_cache[key] if @lookup_cache.key?(key)

      lookup_model = lookup["resource"].to_s.classify.safe_constantize
      record_id = lookup_model&.where(company_id: @company.id, external_id: raw_value.to_s)&.pick(:id)

      @lookup_cache[key] = if record_id
        [ record_id, nil ]
      else
        [ nil, "#{lookup['resource']}: no record with external_id '#{raw_value}'" ]
      end
    end

    def column_type(target)
      @model&.columns_hash&.[](target)&.type
    end

    def cannot_parse(target, raw_value)
      "#{target}: cannot parse '#{raw_value}'"
    end
  end
end
