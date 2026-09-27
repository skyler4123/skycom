class SettingGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_setting_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_setting_group_appointments
end
