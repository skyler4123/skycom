# frozen_string_literal: true

# ApplicantInterview — Atomic purpose: one scheduled interview of one applicant with one interviewer, and its outcome.
#
# Why it exists: hiring decisions are made across several interviews by different people; without a row per interview there is no record of who met the candidate, when, or what they concluded.
# How it works: child of the applicant with the interviewing employee, a time and an outcome enum. Kept even after the applicant is rejected, because hiring audit and bias review depend on the history.
# Main associations: belongs_to :company, :applicant, :employee (optional).
class ApplicantInterview < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :outcome, INTERVIEW_OUTCOMES, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :applicant
  belongs_to :employee, optional: true

  # --- Scopes ---
  scope :upcoming, -> { where(scheduled_at: Time.current..) }

  # --- Validations ---
  validates :scheduled_at, presence: true
end
