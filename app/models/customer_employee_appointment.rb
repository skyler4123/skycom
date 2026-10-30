# frozen_string_literal: true

# CustomerEmployeeAppointment — Atomic purpose: atomic join row binding one
# Customer and one Employee.
#
# Why it exists: one table per resource pair with concrete FKs replaces the old
# polymorphic *_appointments tables (no appoint_to/from/for/by), so joins stay
# index-backed and mismatched pairs are impossible at the schema level.
#
# How to use: create rows directly or through the owning domain service; read
# via the has_many/through declared on either side.
#
# How it works: table and class names use the alphabetical pair order (e.g.
# DepartmentEmployeeAppointment). company_id derives from either side via
# SetDefaultCompanyConcern. The two service-booking tables
# (customer/employee_service_appointments) additionally carry duration/start_at.
#
# Main associations: belongs_to :company, :customer, :employee.
class CustomerEmployeeAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :customer
  belongs_to :employee
end
