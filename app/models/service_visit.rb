# frozen_string_literal: true

# ServiceVisit — Atomic purpose: a scheduled field-service visit: who goes, where, when, and what was done.
#
# Why it exists: dispatching a technician is a schedulable unit with an owner, a site and an outcome; representing it as a calendar event loses the assignment and the parts used, and representing it as a task loses the customer and the site.
# How it works: belongs to a customer and optionally a project and facility (the site), with the assigned employee and the scheduled window. Completed visits keep `completed_at` as evidence; parts consumed are ServiceVisitParts so the van stock and the invoice both reconcile.
# Main associations: belongs_to :company, :customer, :project (optional), :facility (optional), :assigned_employee (optional); has_many :service_visit_parts.
class ServiceVisit < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :customer
  belongs_to :project, optional: true
  belongs_to :facility, optional: true
  belongs_to :assigned_employee, class_name: "Employee", optional: true
  has_many :service_visit_parts, dependent: :destroy

  # --- Scopes ---
  scope :scheduled_between, ->(from, to) { where(scheduled_at: from..to) }
  scope :open_visits, -> { where(status: [ :pending, :confirmed, :in_progress ]) }

  # --- Validations ---
  validates :scheduled_at, presence: true
end
