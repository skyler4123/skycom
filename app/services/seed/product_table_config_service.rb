# frozen_string_literal: true

# Seed::ProductTableConfigService — atomic purpose: backfill the product
# catalog columns into existing product Table Configs.
#
# Why it exists: new companies get the richer product grid from the init seed,
# but companies created before the columns existed keep their old config.
# How it works: idempotently inserts only missing columns in the approved order;
# existing visibility, order, labels, and hidden columns are preserved.
# Run once per environment: bin/rails runner "Seed::ProductTableConfigService.ensure_columns!"
# Main associations: TableConfig (products resource only).
class Seed::ProductTableConfigService
  CORE_COLUMNS = %w[brand price_cents cost_cents stock_quantity unit_of_measure workflow_status].freeze

  def self.ensure_columns!(company: nil)
    scope = TableConfig.where(resource_name: "products")
    scope = scope.where(company_id: company.id) if company

    scope.find_each { |config| ensure_config!(config) }
  end

  def self.ensure_config!(config)
    columns = Array(config.columns).map(&:dup)
    added = false

    CORE_COLUMNS.each do |key|
      next if columns.any? { |column| column["key"] == key }

      columns.insert(insertion_index(columns, key), Seed::TableConfigService.field_hash(key))
      added = true
    end

    return unless added

    config.update!(metadata: (config.metadata || {}).merge("columns" => columns))
  end

  # Keep the approved order even when some core columns already exist:
  # insert after the last present core column that precedes this one.
  def self.insertion_index(columns, key)
    earlier_keys = CORE_COLUMNS.take_while { |core_key| core_key != key }.reverse
    anchor = earlier_keys.filter_map { |core_key| columns.index { |column| column["key"] == core_key } }.first
    anchor = columns.index { |column| column["key"] == "code" } if anchor.nil?
    (anchor || -1) + 1
  end

  private_class_method :ensure_config!, :insertion_index
end
