# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigration, type: :model do
  let!(:company) { create(:company) }

  def build_migration(**attrs)
    CompanyMigration.new(
      {
        company: company,
        folder: Folder.create!(company: company, name: "Import #{SecureRandom.hex(3)}"),
        name: "Customers import"
      }.merge(attrs)
    )
  end

  def create_chunk(migration, chunk_index:, row_count: 0, **counters)
    stored_file = migration.stored_files.new(company: company, folder: migration.folder, name: "part-#{chunk_index}.csv")
    stored_file.file.attach(io: StringIO.new("Index,Customer Id\n1,abc\n"), filename: "part-#{chunk_index}.csv", content_type: "text/csv")
    stored_file.metadata = { "chunk_index" => chunk_index, "row_count" => row_count }.merge(counters.stringify_keys)
    stored_file.save!
    stored_file
  end

  describe "workflow_status" do
    it "maps the migration lifecycle values" do
      expect(described_class.workflow_statuses).to eq(
        "draft" => 0,
        "approved" => 1,
        "processing" => 2,
        "completed" => 3,
        "failed" => 4,
        "rolling_back" => 5,
        "rolled_back" => 6
      )
    end
  end

  describe "validations" do
    it "is invalid without a name" do
      migration = build_migration(name: nil)

      expect(migration).not_to be_valid
      expect(migration.errors[:name]).to be_present
    end
  end

  describe "#ordered_chunks" do
    it "orders chunks by chunk_index, not insertion order" do
      migration = build_migration
      migration.save!
      create_chunk(migration, chunk_index: 2, row_count: 2)
      create_chunk(migration, chunk_index: 0, row_count: 10)
      create_chunk(migration, chunk_index: 1, row_count: 5)

      expect(migration.ordered_chunks.map(&:chunk_index)).to eq([ 0, 1, 2 ])
    end
  end

  describe "#recompute_counters!" do
    it "sums chunk counters into the migration counters" do
      migration = build_migration
      migration.save!
      create_chunk(migration, chunk_index: 0, row_count: 100, processed_rows: 100, created_rows: 80, updated_rows: 10, failed_rows: 10)
      create_chunk(migration, chunk_index: 1, row_count: 200, processed_rows: 50, created_rows: 20, updated_rows: 5, failed_rows: 25)

      migration.recompute_counters!
      migration.reload

      expect(migration.total_chunks).to eq(2)
      expect(migration.total_rows).to eq(300)
      expect(migration.processed_rows).to eq(150)
      expect(migration.created_rows).to eq(100)
      expect(migration.updated_rows).to eq(15)
      expect(migration.failed_rows).to eq(35)
    end
  end

  describe "associations" do
    it "destroys its logs with the migration" do
      migration = create(:company_migration)
      create(:company_migration_log, company_migration: migration, company: migration.company)

      expect { migration.destroy! }.to change(CompanyMigrationLog, :count).by(-1)
    end
  end
end
