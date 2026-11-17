# frozen_string_literal: true

# EmployeeManagerAppointment — Atomic purpose: an explicit reporting line from one employee to a manager, with its type and validity window.
#
# Why it exists: today management is inferred from EmployeeGroup#manager_id, which answers 'who leads my team' but not 'who is my manager' — an employee in three groups has three answers and no primary. An org chart, escalation and approval routing all need the explicit edge.
# How it works: self-link using manager_employee_id, the same shape as EmployeeEmployeeAppointment#related_employee. `relationship_type` separates primary from dotted-line and mentor. Effective dates preserve historic reporting lines after a reorganisation.
# Main associations: belongs_to :company, :employee, :manager_employee (Employee).
class EmployeeManagerAppointment < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :relationship_type, EMPLOYEE_MANAGER_RELATIONSHIPS, prefix: true, default: :primary

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :manager_employee, class_name: "Employee"

  # --- Scopes ---
  scope :current, ->(date = Date.current) {
    where("effective_from IS NULL OR effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }
  scope :primary, -> { where(relationship_type: :primary) }

  # --- Validations ---
  validate :manager_differs_from_employee

  private

  def manager_differs_from_employee
    return if employee_id.blank? || employee_id != manager_employee_id

    errors.add(:manager_employee, "cannot be the employee themselves")
  end
end
