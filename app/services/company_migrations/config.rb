# frozen_string_literal: true

# Interprets CompanyMigration#migration_mapping_config — the JSON document
# that tells the import engine what to write and where:
#
#   { "version": 1,
#     "source": { "has_header": true },
#     "targets": [ { "resource", "identity", "category", "columns", "defaults" } ] }
#
# Generic by design: any Skycom model may be the target except the permission
# machinery (MIGRATION_IMPORT_EXCLUDED_RESOURCES). See docs/DATA_IMPORT.md.
module CompanyMigrations
  class Config
    # Columns the engine owns — a config can never map or default them.
    FORBIDDEN_TARGETS = %w[
      id company_id created_at updated_at discarded_at permission_resource_name property_mapping_id external_id
    ].freeze

    VALID_CATEGORY_MODES = %w[reuse create_or_reuse].freeze
    METADATA_PREFIX = "metadata."

    attr_reader :raw

    def initialize(raw)
      @raw = raw.is_a?(Hash) ? raw : {}
      @errors = []
      validate!
    end

    def valid?
      @errors.empty?
    end

    def errors
      @errors
    end

    def targets
      raw["targets"].is_a?(Array) ? raw["targets"] : []
    end

    def source
      raw["source"].is_a?(Hash) ? raw["source"] : {}
    end

    # Stable identity of the config: any edit changes the digest, which is how
    # a dry-run pass is bound to the exact config it validated.
    def digest
      @digest ||= Digest::SHA256.hexdigest(JSON.generate(deep_sorted(raw)))
    end

    private

    def validate!
      @errors << "version must be 1" unless raw["version"] == 1
      @errors << "source.has_header is required" unless source["has_header"]

      unless raw["targets"].is_a?(Array) && raw["targets"].any?
        @errors << "at least one target is required"
        return
      end

      targets.each_with_index { |target, index| validate_target(target, index) }
    end

    def validate_target(target, index)
      prefix = "targets[#{index}]"

      unless target.is_a?(Hash)
        @errors << "#{prefix}: must be an object"
        return
      end

      model = resolve_model(target["resource"], prefix)

      validate_identity(target["identity"], prefix)
      validate_category(target["category"], prefix)
      validate_columns(target["columns"], prefix, model)
      validate_defaults(target["defaults"], prefix, model)
    end

    def resolve_model(resource, prefix)
      if resource.blank?
        @errors << "#{prefix}: resource is required"
        return nil
      end

      model = resource.to_s.classify.safe_constantize

      if model.nil? || !model.respond_to?(:columns_hash)
        @errors << "#{prefix}: unknown model '#{resource}'"
        return nil
      end

      if MIGRATION_IMPORT_EXCLUDED_RESOURCES.include?(model.name)
        @errors << "#{prefix}: '#{resource}' is not importable"
        return nil
      end

      unless model.columns_hash.key?("company_id")
        @errors << "#{prefix}: '#{resource}' is not company-scoped"
        return nil
      end

      model
    end

    def validate_identity(identity, prefix)
      return if identity.is_a?(Hash) && identity["column"].present?

      @errors << "#{prefix}: identity.column is required"
    end

    def validate_category(category, prefix)
      unless category.is_a?(Hash)
        @errors << "#{prefix}: category is required"
        return
      end

      case category["mode"]
      when "reuse"
        @errors << "#{prefix}: category.category_id is required for reuse" if category["category_id"].blank?
      when "create_or_reuse"
        @errors << "#{prefix}: category.name is required for create_or_reuse" if category["name"].blank?
      else
        @errors << "#{prefix}: category.mode must be one of #{VALID_CATEGORY_MODES.join(', ')}"
      end
    end

    def validate_columns(columns, prefix, model)
      unless columns.is_a?(Hash)
        @errors << "#{prefix}: columns must be an object"
        return
      end

      columns.each do |source_column, mapping|
        label = "#{prefix}.columns['#{source_column}']"

        unless mapping.is_a?(Hash) && mapping["target"].present?
          @errors << "#{label}: target is required"
          next
        end

        validate_target_field(mapping["target"], label, model, lookup: mapping["lookup"])
      end
    end

    def validate_defaults(defaults, prefix, model)
      return if defaults.blank?

      unless defaults.is_a?(Hash)
        @errors << "#{prefix}: defaults must be an object"
        return
      end

      defaults.each_key do |target|
        validate_target_field(target, "#{prefix}.defaults['#{target}']", model)
      end
    end

    def validate_target_field(target, label, model, lookup: nil)
      return if model.nil?

      if target.start_with?(METADATA_PREFIX)
        @errors << "#{label}: metadata key is required" if target.delete_prefix(METADATA_PREFIX).blank?
        return
      end

      if FORBIDDEN_TARGETS.include?(target)
        @errors << "#{label}: '#{target}' cannot be imported"
        return
      end

      if target.start_with?("property_")
        unless Seed::CategoryService::PROPERTY_SLOT_KEYS.include?(target)
          @errors << "#{label}: unknown property slot '#{target}'"
        end
        return
      end

      unless model.columns_hash.key?(target)
        @errors << "#{label}: '#{target}' is not a column of #{model.name}"
        return
      end

      return if lookup.blank?

      validate_lookup(lookup, label)
    end

    def validate_lookup(lookup, label)
      valid_shape = lookup.is_a?(Hash) && lookup["resource"].present? && lookup["by"] == "external_id"

      unless valid_shape
        @errors << "#{label}: lookup must be { resource, by: 'external_id' }"
        return
      end

      return if lookup["resource"].to_s.classify.safe_constantize.respond_to?(:columns_hash)

      @errors << "#{label}: unknown lookup model '#{lookup['resource']}'"
    end

    def deep_sorted(value)
      case value
      when Hash
        value.sort.to_h { |key, nested| [ key, deep_sorted(nested) ] }
      when Array
        value.map { |nested| deep_sorted(nested) }
      else
        value
      end
    end
  end
end
