class EventServiceAppointment < ApplicationRecord
  # Pairwise link — atomic join row binding exactly two records (Event ↔ Service).
  #
  # Why it exists: one table per resource pair with concrete FKs replaces the old
  # polymorphic *_appointments tables (no appoint_to/from/for/by), so joins stay
  # index-backed and mismatched pairs are impossible at the schema level.
  # How to use: create rows directly or through the owning domain service; read
  # via the has_many/through declared on either side. The optional `role`
  # records what the service is for in this event (procedure/package/…).
  # How it works: table and class names use the alphabetical pair order
  # (Event < Service). company_id derives from either side
  # via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :event
  belongs_to :service
end
