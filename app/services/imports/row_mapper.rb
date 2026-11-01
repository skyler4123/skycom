# frozen_string_literal: true

require "bigdecimal"

# Maps one CSV row to model attributes using the Import header contract.
# Values are coerced by the destination type with explicit per-column errors —
# AR's silent casting (e.g. "abc".to_i == 0) is never relied on. Foreign keys
# must be well-formed UUIDs that resolve inside the same company.
module Imports
  class RowMapper
    TRUE_VALUES = %w[1 true yes y on].freeze
    FALSE_VALUES = %w[0 false no n off].freeze
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    def self.call(company:, schema:, model:, csv_row:)
      new(company: company, schema: schema, model: model).map(csv_row)
    end

    def initialize(company:, schema:, model:)
      @company = company
      @schema = schema
      @model = model
      @entries = schema["headers"] || []
      @association_cache = {}
    end

    # => { attrs: { "name" => "…", "property_string_1" => "…" }, errors: ["…"] }
    def map(csv_row)
      attrs = {}
      errors = []

      @entries.each do |entry|
        value, error = cast(entry, csv_row[entry["header"]])

        if error
          errors << error
        elsif !value.nil?
          attrs[entry["attribute"]] = value
        end
      end

      { attrs: attrs, errors: errors }
    end

    private

    def cast(entry, raw)
      value = raw.to_s.strip
      return [ nil, nil ] if value.empty?

      case entry["type"]
      when "integer" then cast_integer(entry, value)
      when "decimal" then cast_decimal(entry, value)
      when "boolean" then cast_boolean(entry, value)
      when "datetime" then cast_datetime(entry, value)
      when "uuid" then cast_uuid(entry, value)
      when "enum" then cast_enum(entry, value)
      else [ value, nil ]
      end
    end

    def cast_integer(entry, value)
      [ Integer(value), nil ]
    rescue ArgumentError, TypeError
      parse_error(entry, value)
    end

    def cast_decimal(entry, value)
      [ BigDecimal(value), nil ]
    rescue ArgumentError, TypeError
      parse_error(entry, value)
    end

    def cast_boolean(entry, value)
      normalized = value.downcase
      return [ true, nil ] if TRUE_VALUES.include?(normalized)
      return [ false, nil ] if FALSE_VALUES.include?(normalized)

      [ nil, "#{entry['header']}: '#{value}' is not a boolean (#{TRUE_VALUES.join(', ')} / #{FALSE_VALUES.join(', ')})" ]
    end

    def cast_datetime(entry, value)
      parsed = Time.zone.parse(value)
      return [ parsed, nil ] if parsed

      parse_error(entry, value)
    rescue ArgumentError
      parse_error(entry, value)
    end

    def cast_uuid(entry, value)
      return parse_error(entry, value) unless UUID_PATTERN.match?(value)

      association_error = association_error(entry, value)
      return [ nil, association_error ] if association_error

      [ value, nil ]
    end

    def cast_enum(entry, value)
      mapping = @model.defined_enums[entry["attribute"]] || {}
      return [ value, nil ] if mapping.key?(value)

      if value.match?(/\A\d+\z/) && mapping.value?(value.to_i)
        return [ value.to_i, nil ]
      end

      allowed = mapping.keys.first(10).join(", ")
      allowed += ", …" if mapping.size > 10
      [ nil, "#{entry['header']}: '#{value}' is not a valid value (allowed: #{allowed})" ]
    end

    def association_error(entry, value)
      association = entry["association"]
      return nil if association.blank?

      klass = association["model"].to_s.safe_constantize
      return "#{entry['header']}: unknown association" if klass.nil?

      cache_key = [ association["model"], value ]
      return @association_cache[cache_key] if @association_cache.key?(cache_key)

      scope = klass.column_names.include?("company_id") ? klass.where(company_id: @company.id) : klass
      found = scope.exists?(id: value)
      error = if found
        nil
      elsif klass.column_names.include?("company_id")
        "#{entry['header']}: no record found in this company"
      else
        "#{entry['header']}: no record found"
      end

      @association_cache[cache_key] = error
    end

    def parse_error(entry, value)
      [ nil, "#{entry['header']}: cannot parse '#{value}'" ]
    end
  end
end
