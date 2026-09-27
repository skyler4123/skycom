class Article < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :article_group
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :article_employee_appointments, dependent: :destroy
  has_many :employees, through: :article_employee_appointments
end
