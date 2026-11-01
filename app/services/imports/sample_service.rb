# frozen_string_literal: true

# Renders the latest IMPORT_PREVIEW_ROW_LIMIT records for an Import's target
# table + category using the resolved header contract. This is the "what your
# CSV should look like" sample: property columns appear under their category
# display names (never property_string_1) and enum columns show labels.
module Imports
  class SampleService
    def self.call(company:, schema:, model:, category:)
      new(company: company, schema: schema, model: model, category: category).call
    end

    def initialize(company:, schema:, model:, category:)
      @company = company
      @schema = schema
      @model = model
      @category = category
    end

    def call
      headers = @schema["headers"] || []
      return { "headers" => [], "rows" => [], "total_records" => 0 } if headers.empty?

      scope = @model.where(company_id: @company.id)
      scope = scope.where(category_id: @category.id) if @category.present?
      total = scope.count

      rows = scope.order(created_at: :desc).limit(IMPORT_PREVIEW_ROW_LIMIT).map do |record|
        headers.each_with_object({}) do |entry, row|
          row[entry["header"]] = display_value(record, entry)
        end
      end

      {
        "headers" => headers.map { |entry| entry.slice("header", "kind", "type") },
        "rows" => rows,
        "total_records" => total
      }
    end

    private

    def display_value(record, entry)
      value = record.public_send(entry["attribute"])

      case entry["type"]
      when "enum"
        enum_label(entry["attribute"], value)
      when "boolean"
        value.nil? ? nil : value.to_s
      when "datetime"
        value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
      when "decimal"
        value.is_a?(BigDecimal) ? value.to_s("F") : value
      else
        value
      end
    end

    def enum_label(column, value)
      mapping = @model.defined_enums[column] || {}
      label = mapping.key(value) || mapping.key(value.to_i)
      label || value
    end
  end
end
