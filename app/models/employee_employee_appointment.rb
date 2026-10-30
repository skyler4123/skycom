# frozen_string_literal: true

# EmployeeEmployeeAppointment — Atomic purpose: atomic join row binding one
# Employee and one related Employee.
#
# Why it exists: one table per resource pair with concrete FKs replaces the old
# polymorphic *_appointments tables (no appoint_to/from/for/by), so joins stay
# index-backed and mismatched pairs are impossible at the schema level. This
# self-link uses related_employee_id for the second side.
#
# How to use: create rows directly or through the owning domain service; read
# via the has_many/through declared on either side.
#
# How it works: table and class names use the alphabetical pair order (e.g.
# DepartmentEmployeeAppointment). company_id derives from either side via
# SetDefaultCompanyConcern. The two service-booking tables
# (customer/employee_service_appointments) additionally carry duration/start_at.
#
# Main associations: belongs_to :company, :employee, :related_employee
# (Employee).
class EmployeeEmployeeAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :employee
  belongs_to :related_employee, class_name: "Employee"
end
