# frozen_string_literal: true

# Resolves the exact CSV header contract for an Import:
#
#   Imports::SchemaResolver.call(
#     company:, target_table: "products", category: category
#   ) # => { success:, errors:, schema:, model:, category: }
#
# Headers are the target model's own column names (technical, exact) plus the
# selected category's property display names ("Skin Type Suitability" →
# property_string_1). The target table is looked up in IMPORTABLE_RESOURCES —
# user input is never constantized. Engine-owned columns, property_* slots, and
# JSON columns are excluded from the plain-column list.
module Imports
  class SchemaResolver
    NAME_FIRST = ->(column) { column == "name" ? "0" : "1#{column}" }

    def self.call(company:, target_table:, category:)
      new(company: company, target_table: target_table, category: category).call
    end

    def initialize(company:, target_table:, category:)
      @company = company
      @target_table = target_table.to_s
      @category = category
    end

    def call
      model_name = IMPORTABLE_RESOURCES[@target_table]
      return failure("'#{@target_table}' is not importable") if model_name.nil?

      @model = model_name.safe_constantize
      return failure("unknown model '#{model_name}'") if @model.nil?
      return failure("'#{@target_table}' is not company-scoped") unless @model.column_names.include?("company_id")

      category_error = validate_category
      return failure(category_error) if category_error

      headers = column_headers + property_headers
      duplicate = headers.group_by { |entry| entry["header"] }.find { |_, entries| entries.size > 1 }
      return failure("header '#{duplicate.first}' is defined more than once") if duplicate

      schema = {
        "target_table" => @target_table,
        "target_model" => @model.name,
        "category_id" => @category.id,
        "headers" => headers
      }
      schema["digest"] = SchemaDigest.call(schema)

      { success: true, errors: [], schema: schema, model: @model, category: @category }
    rescue StandardError => e
      failure("#{e.class}: #{e.message}")
    end

    private

    def validate_category
      return "category is required" if @category.nil?
      return "category does not belong to this company" unless @category.company_id == @company.id

      expected_resource = @target_table
      return "category '#{@category.name}' is not for '#{expected_resource}'" unless @category.resource_name == expected_resource
      return "category '#{@category.name}' has no property mapping" if @category.default_property_mapping.nil?

      nil
    end

    def column_headers
      @model.column_names
        .reject { |column| IMPORT_ENGINE_COLUMNS.include?(column) }
        .reject { |column| column.start_with?("property_") }
        .reject { |column| %i[json jsonb].include?(@model.columns_hash[column]&.type) }
        .sort_by(&NAME_FIRST)
        .map { |column| column_header(column) }
    end

    def column_header(column)
      enum_values = @model.defined_enums[column]

      {
        "header" => column,
        "attribute" => column,
        "kind" => "column",
        "type" => enum_values ? "enum" : column_type(column),
        "required" => required_column?(column),
        "enum" => enum_values && enum_values.size <= 30 ? enum_values.keys : nil,
        "association" => association_info(column)
      }
    end

    def column_type(column)
      case @model.columns_hash[column]&.type
      when :uuid then "uuid"
      when :integer then "integer"
      when :decimal, :float then "decimal"
      when :boolean then "boolean"
      when :datetime, :date, :time then "datetime"
      else "string"
      end
    end

    def required_column?(column)
      db_column = @model.columns_hash[column]
      db_required = db_column.present? && !db_column.null && db_column.default.nil? && !db_column.primary

      presence_validated = @model.validators_on(column).any? do |validator|
        validator.is_a?(ActiveModel::Validations::PresenceValidator)
      end

      db_required || presence_validated || required_foreign_keys.include?(column)
    end

    def required_foreign_keys
      @required_foreign_keys ||= @model
        .reflect_on_all_associations(:belongs_to)
        .reject { |reflection| reflection.options[:optional] || reflection.polymorphic? }
        .map(&:foreign_key)
        .reject { |column| IMPORT_ENGINE_COLUMNS.include?(column) }
    end

    def association_info(column)
      reflection = @model.reflect_on_all_associations(:belongs_to).find do |candidate|
        !candidate.polymorphic? && candidate.foreign_key == column
      end
      return nil if reflection.nil?

      association_class = reflection.klass
      {
        "model" => association_class.name,
        "foreign_key" => column,
        "company_scoped" => association_class.column_names.include?("company_id")
      }
    rescue NameError
      nil
    end

    def property_headers
      (@category.default_property_mapping.properties || []).filter_map do |config|
        key = config["key"].to_s
        name = config["name"].to_s
        next if key.blank? || name.blank?
        next unless @model.column_names.include?(key)

        {
          "header" => name,
          "attribute" => key,
          "kind" => "property",
          "type" => config["type"].presence || key.split("_")[1] || "string",
          "required" => config.dig("validates", "presence") == true,
          "enum" => nil,
          "association" => nil
        }
      end
    end

    def failure(message)
      { success: false, errors: [ message ], schema: nil, model: nil, category: nil }
    end
  end
end
