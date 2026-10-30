# frozen_string_literal: true

# TagWarehouseAppointment — Atomic purpose: atomic pairwise row binding one Tag
# to one Warehouse.
#
# Why it exists: tags drive the ABAC permission engine (see docs/ABAC.md); this
# table records WHICH tag key/values apply to a record, replacing the old
# polymorphic tag_appointments table.
#
# How to use: never create rows directly — call `record.attach_tag(key:, value:,
# description:)` (see TagConcern); read via `record.tags`.
#
# How it works: table/association names follow the alphabetical pair order —
# "Tag" sorts before Task/TaskGroup/Transaction/Warehouse, so this table is
# Tag-first. company_id derives from the tagged record via
# SetDefaultCompanyConcern.
#
# Main associations: belongs_to :company, :tag, :warehouse.
class TagWarehouseAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :tag
  belongs_to :warehouse
end
