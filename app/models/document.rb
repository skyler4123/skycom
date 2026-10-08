class Document < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include Document::AttachmentConcern

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    policy: 1,
    guide: 2,
    announcement: 3
  }, prefix: true

  belongs_to :document_group
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :document_employee_appointments, dependent: :destroy
  has_many :employees, through: :document_employee_appointments

  # --- Validations ---
  validates :title, presence: true
  validates :body_markdown, length: { maximum: 100_000 }, allow_blank: true
end
