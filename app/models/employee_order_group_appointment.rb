class EmployeeOrderGroupAppointment < ApplicationRecord
  # Order-group line — atomic row binding an Employee to an OrderGroup batch.
  #
  # Why it exists: carries the batch line economics
  # (quantity/unit_price/total_price) per employee within a grouped order.
  # How to use: managed by the order-group flow; read via
  # `employee.employee_order_group_appointments` / `employee.order_groups`.
  # How it works: concrete FKs to company/employee/order_group; company_id
  # derives via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :employee
  belongs_to :order_group
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
