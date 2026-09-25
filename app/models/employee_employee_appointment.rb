class EmployeeEmployeeAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :employee
  belongs_to :related_employee, class_name: "Employee"
end
