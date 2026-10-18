# frozen_string_literal: true

# Validates that a CompanyMigration is ready to be dry-run/imported: chunks
# exist, the config parses, and the target table carries the unique
# [company_id, external_id] index the upsert write path depends on.
module CompanyMigrations
  class Preflight
    IDENTITY_INDEX_COLUMNS = %w[company_id external_id].freeze

    def self.call(company_migration:)
      new(company_migration).call
    end

    def initialize(company_migration)
      @migration = company_migration
      @config = company_migration.config
    end

    def call
      errors = []
      chunks = @migration.ordered_chunks

      if chunks.empty?
        errors << "no chunks uploaded yet"
      elsif !chunks.first.file.attached?
        errors << "first chunk has no file attached"
      end

      errors.concat(@config.errors) unless @config.valid?
      return failure(errors) if errors.any?

      target = @config.targets.first
      model = target["resource"].to_s.classify.safe_constantize
      index = identity_index(model)

      if index.nil?
        return failure([ "#{target['resource']} is missing a unique index on [company_id, external_id] — add it before importing" ])
      end

      { success: true, errors: [], model: model, target: target, identity_index_name: index.name }
    end

    private

    def failure(errors)
      { success: false, errors: errors, model: nil, target: nil, identity_index_name: nil }
    end

    def identity_index(model)
      model.connection.indexes(model.table_name).find do |index|
        index.unique && index.columns.sort == IDENTITY_INDEX_COLUMNS
      end
    end
  end
end
