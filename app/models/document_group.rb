class DocumentGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    policies: 1,
    benefits: 2,
    development: 3
  }, prefix: true

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :document_group_employee_appointments, dependent: :destroy
  has_many :employees, through: :document_group_employee_appointments
end
