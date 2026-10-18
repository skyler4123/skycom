# frozen_string_literal: true

# Resolves (or creates) the Category a config target imports into, along with
# its property mapping and table config — reusing the seeding services so an
# import configures dynamic properties exactly like seeds do.
#
#   CompanyMigrations::CategoryResolver.call(
#     company:, resource:, category_config:
#   ) # => { success:, category:, errors: }
#
# category_config shapes (validated by CompanyMigrations::Config):
#   { "mode" => "reuse", "category_id" => "..." }
#   { "mode" => "create_or_reuse", "name" => "...", "properties" => {...}, "visible_columns" => [...] }
module CompanyMigrations
  class CategoryResolver
    def self.call(company:, resource:, category_config:)
      new(company: company, resource: resource, category_config: category_config).call
    end

    def initialize(company:, resource:, category_config:)
      @company = company
      @resource = resource
      @category_config = category_config.is_a?(Hash) ? category_config : {}
    end

    def call
      category = @category_config["mode"] == "reuse" ? find_by_id : find_or_create

      return { success: false, category: nil, errors: [ "category not found: #{@category_config['category_id'] || @category_config['name']}" ] } if category.nil?

      apply_table_config(category)
      { success: true, category: category, errors: [] }
    end

    private

    def find_by_id
      @company.categories.find_by(id: @category_config["category_id"])
    end

    def find_or_create
      existing = @company.categories.find_by(name: @category_config["name"], resource_name: @resource)
      return existing if existing

      Seed::CategoryService.create(
        company: @company,
        name: @category_config["name"],
        resource_name: @resource,
        properties: @category_config["properties"] || {}
      )
    end

    def apply_table_config(category)
      visible_columns = @category_config["visible_columns"]
      return if visible_columns.blank?

      # Property columns must carry the PropertyMapping's display name — the
      # TableConfig validation rejects humanized defaults for property_* keys
      # (same contract the seed init services honor via field_hash(key, name)).
      property_names = property_names_for(category)

      Seed::TableConfigService.create(
        company: @company,
        resource_name: @resource,
        category: category,
        columns_metadata: visible_columns.map { |key| Seed::TableConfigService.field_hash(key, property_names[key]) }
      )
    end

    def property_names_for(category)
      (category.default_property_mapping.properties || []).each_with_object({}) do |entry, names|
        names[entry["key"]] = entry["name"]
      end
    end
  end
end
