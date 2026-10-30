# frozen_string_literal: true

# CustomerServiceAppointment — Atomic purpose: atomic join row binding one
# Customer and one Service.
#
# Why it exists: one table per resource pair with concrete FKs replaces the old
# polymorphic *_appointments tables (no appoint_to/from/for/by), so joins stay
# index-backed and mismatched pairs are impossible at the schema level.
#
# How to use: create rows directly or through the owning domain service; read
# via the has_many/through declared on either side. This service-booking table
# additionally carries duration/start_at for the booked slot.
#
# How it works: table and class names use the alphabetical pair order (e.g.
# DepartmentEmployeeAppointment). company_id derives from either side via
# SetDefaultCompanyConcern.
#
# Main associations: belongs_to :company, :customer, :service.
class CustomerServiceAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :customer
  belongs_to :service
end
