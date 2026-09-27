class DocumentGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :document_group_employee_appointments, dependent: :destroy
  has_many :employees, through: :document_group_employee_appointments
end
