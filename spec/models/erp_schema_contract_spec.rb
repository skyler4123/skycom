# spec/models/erp_schema_contract_spec.rb
#
# Contract for the ERP schema wave (91 tables created 2026-11-17).
# Every table must always have exactly one model whose table_name matches, and
# every belongs_to must resolve — this is what catches a typo in a migration
# filename, a missing constant, or a broken inflection before anything uses it.
require "rails_helper"

RSpec.describe "ERP schema contract" do
  def erp_tables
    Dir[Rails.root.join("db/migrate/20261117000*_create_*.rb")].map do |path|
      File.basename(path).sub(/\A\d+_create_/, "").sub(/\.rb\z/, "")
    end.sort
  end

  it "created 91 tables" do
    expect(erp_tables.size).to eq(91)
  end

  it "has one model per table, with a matching table_name" do
    Rails.application.eager_load!
    by_table = ApplicationRecord.descendants.reject(&:abstract_class?).index_by(&:table_name)

    missing = erp_tables.reject { |table| by_table.key?(table) }
    expect(missing).to eq([])

    mismatched = erp_tables.filter_map do |table|
      klass = by_table[table]
      next if klass.table_name == table

      "#{klass.name} -> #{klass.table_name} (expected #{table})"
    end
    expect(mismatched).to eq([])
  end

  it "resolves every belongs_to association" do
    Rails.application.eager_load!
    failures = []

    ApplicationRecord.descendants.reject(&:abstract_class?).each do |klass|
      next unless erp_tables.include?(klass.table_name)

      klass.reflect_on_all_associations(:belongs_to).each do |assoc|
        next if assoc.polymorphic?

        assoc.klass
      rescue StandardError => e
        failures << "#{klass.name}##{assoc.name}: #{e.message}"
      end
    end

    expect(failures).to eq([])
  end

  it "resolves every has_many association, including the wiring on existing models" do
    Rails.application.eager_load!
    wired = %w[Company Customer Document Employee Invoice Order Payroll Product Project
      Purchase Stock StockImport StockTransaction StoredFile Supplier Task Warehouse]

    failures = ApplicationRecord.descendants.reject(&:abstract_class?).filter_map do |klass|
      next unless erp_tables.include?(klass.table_name) || wired.include?(klass.name)

      klass.reflect_on_all_associations(:has_many).each do |assoc|
        next if assoc.polymorphic?

        assoc.klass
      rescue StandardError => e
        "#{klass.name}##{assoc.name}: #{e.message}"
      end
      nil
    end

    expect(failures).to eq([])
  end

  it "keeps the ledger idempotency guard in the database" do
    indexes = ActiveRecord::Base.connection.indexes(:journal_entries)

    expect(indexes).to include(
      having_attributes(
        name: "idx_journal_entries_idempotency",
        unique: true,
        columns: %w[company_id source_type source_id event_key]
      )
    )
  end

  it "creates no duplicate index names across the new tables" do
    names = erp_tables.flat_map do |table|
      ActiveRecord::Base.connection.indexes(table).map(&:name)
    end

    expect(names.tally.select { |_name, count| count > 1 }).to eq({})
  end
end
