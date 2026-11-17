# frozen_string_literal: true

# Applicant — Atomic purpose: one candidate applying for one job opening, with their stage and resume.
#
# Why it exists: hiring is a pipeline: the same person may apply twice in two years, and the record of where they stopped is what makes rejection reasons and time-to-hire measurable.
# How it works: belongs to a job opening; the stage is an enum so funnel reporting is a group-by. The resume is a StoredFile (reusing storage, permissions and download), and stage transitions also write WorkflowStepLog when a workflow is bound.
# Main associations: belongs_to :company, :job_opening, :resume_stored_file (optional), :workflow_step (optional); has_many :applicant_interviews.
class Applicant < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :stage, APPLICANT_STAGES, prefix: true, default: :applied

  # --- Associations ---
  belongs_to :company
  belongs_to :job_opening
  belongs_to :resume_stored_file, class_name: "StoredFile", optional: true
  belongs_to :workflow_step, optional: true
  has_many :applicant_interviews, dependent: :destroy

  # --- Scopes ---
  scope :in_pipeline, -> { where(stage: [ :applied, :screening, :interview, :offer ]) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
end
