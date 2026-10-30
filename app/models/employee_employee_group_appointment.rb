# frozen_string_literal: true

# EmployeeEmployeeGroupAppointment — Atomic purpose: atomic join row binding one
# Employee and one EmployeeGroup.
#
# Why it exists: one table per resource pair with concrete FKs replaces the old
# polymorphic *_appointments tables (no appoint_to/from/for/by), so joins stay
# index-backed and mismatched pairs are impossible at the schema level.
#
# How to use: create rows directly or through the owning domain service; read
# via the has_many/through declared on either side. The group's manager is
# enrolled like any other member — EmployeeGroup#manager_id remains the source of
# truth for who manages the team.
#
# How it works: table and class names use the alphabetical pair order (e.g.
# DepartmentEmployeeAppointment). company_id derives from either side via
# SetDefaultCompanyConcern. The two service-booking tables
# (customer/employee_service_appointments) additionally carry duration/start_at.
#
# Main associations: belongs_to :company, :employee, :employee_group.
class EmployeeEmployeeGroupAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :employee
  belongs_to :employee_group

  after_save :clear_employee_managers_cache
  after_destroy :clear_employee_managers_cache

  private

  def clear_employee_managers_cache
    Employee.find_by(id: employee_id)&.clear_managers_cache
  end
end
