# frozen_string_literal: true

# Document — Atomic purpose: company-scoped document/policy/guide/announcement
# with a markdown body and optional attachments.
#
# Why it exists: stores internal documents once and assigns them to employees
# through an atomic appointment, while supporting the category/property schema
# and tags.
# How it works: belongs to company/branch/category/property mapping; employees
# join through DocumentEmployeeAppointment. AttachmentConcern adds file
# attachments; workflow status moves draft → published → archived.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :employees through
# :document_employee_appointments (dependent: :destroy).
class Document < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include Document::AttachmentConcern

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, { draft: 0, published: 1, archived: 2 }, prefix: true, default: :draft
  enum :business_type, {
    general: 0,
    policy: 1,
    guide: 2,
    announcement: 3
  }, prefix: true

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :document_employee_appointments, dependent: :destroy
  has_many :employees, through: :document_employee_appointments

  # --- Scopes ---
  scope :announcements, -> { where(business_type: :announcement) }
  scope :published, -> { where(workflow_status: :published) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :body_markdown, length: { maximum: 100_000 }, allow_blank: true
end
