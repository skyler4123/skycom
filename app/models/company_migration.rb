# frozen_string_literal: true

# CompanyMigration — Atomic purpose: one CSV/data migration job for a company,
# tracked as a state machine over uploaded chunks.
#
# Why it exists: large imports must be dry-run, approved, executed in chunks, and
# rolled back safely; this row owns the mapping config, counters, and lifecycle
# state (see docs/DATA_MIGRATION.md).
# How it works: `config` parses migration_mapping_config; approve requires at
# least one uploaded chunk and a dry run matching the current config digest;
# counters are recomputed from ordered StoredFile chunks. Progress and per-record
# changes are written to CompanyMigrationLog.
# Main associations: belongs_to :company (touch), :folder; has_many
# :stored_files (as: :attachable), :company_migration_logs (dependent: :destroy).
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

  # Parsed view of migration_mapping_config — the document that tells the
  # import engine what to write and where. Rebuilt per call (a memo would let
  # a stale digest pass the approve guard right after a config edit).
  def config
    CompanyMigrations::Config.new(migration_mapping_config)
  end

  # A passing dry run only counts for the exact config it validated: any
  # config edit changes the digest and disables approve again.
  def dry_run_passed_for_current_config?
    dry_run_result.is_a?(Hash) && dry_run_result["passed"] == true && dry_run_result["config_digest"] == config.digest
  end

  # Approve is allowed from draft/failed once at least one chunk is uploaded
  # and the current config passed its dry run.
  def approvable?
    (workflow_status_draft? || workflow_status_failed?) && total_chunks.positive? && config.valid? && dry_run_passed_for_current_config?
  end

  # Rails-style: only the company's latest completed migration can be rolled
  # back — a later import may reference (or have modified) its records.
  def rollbackable?
    workflow_status_completed? && company.company_migrations.where(workflow_status: :completed).where("completed_at > ?", completed_at).none?
  end

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
