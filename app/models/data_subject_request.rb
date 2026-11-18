# frozen_string_literal: true

# DataSubjectRequest — Atomic purpose: one privacy request (access, erasure, portability, rectification) from a data subject, with its deadline and outcome.
#
# Why it exists: a deletion request has a legal clock and must be provable: who asked, what was done, when. Handling it by email makes the company unable to answer an auditor or a regulator months later.
# How it works: belongs to a company and to whichever subject type applies (customer, employee or user) — exactly one is set by validation. Status is an enum so an in-flight request is distinguishable from a rejected one; `completed_at` is the evidence.
# Main associations: belongs_to :company, :customer (optional), :employee (optional), :user (optional).
class DataSubjectRequest < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :request_type, DATA_SUBJECT_REQUEST_TYPES, prefix: true, default: :access
  enum :status, DATA_SUBJECT_REQUEST_STATUSES, prefix: true, default: :received

  # --- Associations ---
  belongs_to :company
  belongs_to :customer, optional: true
  belongs_to :employee, optional: true
  belongs_to :user, optional: true

  # --- Scopes ---
  scope :open_requests, -> { where(status: [ :received, :in_progress ]) }

  # --- Validations ---
  validate :exactly_one_subject

  private

  def exactly_one_subject
    return if [ customer_id, employee_id, user_id ].compact.size == 1

    errors.add(:base, "must reference exactly one data subject")
  end
end
