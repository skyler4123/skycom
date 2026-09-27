class ServiceTagAppointment < ApplicationRecord
  # Tag assignment — atomic pairwise row binding one Tag to its tagged record.
  #
  # Why it exists: tags drive the ABAC permission engine (see docs/ABAC.md); this
  # table records WHICH tag key/values apply to a record, replacing the old
  # polymorphic tag_appointments table.
  # How to use: never create rows directly — call
  # `record.attach_tag(key:, value:, description:)` (see TagConcern); read via
  # `record.tags`.
  # How it works: table/association names follow the alphabetical pair order
  # (e.g. ArticleTagAppointment — Tag-first for Task/TaskGroup/Transaction/
  # Warehouse, e.g. TagTaskAppointment). company_id derives from the tagged
  # record via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :service
  belongs_to :tag
end
