class CompanyMigration < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :error_samples, :source_header, :rollback_total, :rollback_processed

  # --- Enums ---
  enum :workflow_status, {
    draft: 0,
    approved: 1,
    processing: 2,
    completed: 3,
    failed: 4,
    rolling_back: 5,
    rolled_back: 6
  }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :business_type, { general: 0 }, prefix: true

  # --- Associations ---
  belongs_to :company, touch: true
  belongs_to :folder
  has_many :stored_files, as: :attachable, dependent: :destroy
  has_many :company_migration_logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  # Chunks in playback order (upload order is the source of truth for the import).
  def ordered_chunks
    stored_files.to_a.sort_by { |chunk| chunk.chunk_index.to_i }
  end

  # Migration counters are always derived from the chunk-level counters so a
  # resumed (partially re-run) chunk can never double count.
  def recompute_counters!
    chunks = ordered_chunks

    update_columns(
      total_chunks: chunks.size,
      total_rows: chunks.sum { |chunk| chunk.row_count.to_i },
      processed_rows: chunks.sum { |chunk| chunk.processed_rows.to_i },
      created_rows: chunks.sum { |chunk| chunk.created_rows.to_i },
      updated_rows: chunks.sum { |chunk| chunk.updated_rows.to_i },
      failed_rows: chunks.sum { |chunk| chunk.failed_rows.to_i }
    )
  end
end
