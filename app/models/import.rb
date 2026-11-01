# frozen_string_literal: true

# Import — Atomic purpose: one user-prepared CSV import run for a company,
# tracked as a state machine over a single uploaded file.
#
# Why it exists: the Import feature assumes the user knows the target schema.
# One row owns the chosen target table, the single category that gives the
# dynamic property headers their meaning, the uploaded CSV, the dry-run
# result, counters, and the approve → run / rollback lifecycle.
# How it works: Imports::SchemaResolver turns target_table + category into the
# exact header contract; Imports::DryRunService validates every row and stores
# a passing result bound to both digests; Imports::RunService creates rows and
# writes ImportLog audit rows; Imports::RollbackService replays those logs.
# Main associations: belongs_to :company, :folder, :creator (Employee),
# :category (optional); has_one :source_file (StoredFile, polymorphic);
# has_many :import_logs (dependent: :destroy).
class Import < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :workflow_status, :integer, default: -> { IMPORT_WORKFLOW_STATUS[:draft] }

  # --- Enums ---
  enum :workflow_status, IMPORT_WORKFLOW_STATUS, prefix: true
  enum :business_type, { general: 0 }, prefix: true

  # --- Associations ---
  belongs_to :company, touch: true
  belongs_to :folder
  belongs_to :creator, class_name: "Employee", optional: true
  belongs_to :category, optional: true
  has_one :source_file, as: :attachable, class_name: "StoredFile", dependent: :destroy
  has_many :import_logs, dependent: :destroy

  # --- Scopes ---
  scope :recent, -> { order(created_at: :desc) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
  validates :creator, presence: true
  validate :target_table_is_importable

  # Model name shown in the UI for the chosen table (nil until one is picked).
  def target_model_name
    IMPORTABLE_RESOURCES[target_table]
  end

  # Edits, uploads, and dry runs are only possible while draft. A failed run is
  # terminal: the user rolls back partial rows and starts a new import.
  def setup_locked?
    !workflow_status_draft?
  end

  # Approve requires a live file, a resolvable schema, and a passing dry run
  # bound to both the current schema digest and the current source digest.
  def approvable?
    return false unless workflow_status_draft?
    return false if source_file.nil? || target_table.blank? || category.nil?

    result = Imports::SchemaResolver.call(company: company, target_table: target_table, category: category)
    return false unless result[:success]

    dry_run_passed_for?(result[:schema])
  end

  # Rollback is available from a completed run (normal) or a failed one
  # (partial rows). Rolled-back imports cannot be rolled back again.
  def rollbackable?
    workflow_status_completed? || workflow_status_failed?
  end

  def dry_run_passed_for?(schema)
    return false unless dry_run_result.is_a?(Hash)

    dry_run_result["passed"] == true &&
      dry_run_result["schema_digest"] == schema["digest"] &&
      dry_run_result["source_digest"] == source_digest
  end

  private

  def target_table_is_importable
    return if target_table.blank?
    return if IMPORTABLE_RESOURCES.key?(target_table)

    errors.add(:target_table, "is not importable")
  end
end
