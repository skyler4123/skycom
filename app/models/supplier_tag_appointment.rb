# frozen_string_literal: true

# SupplierTagAppointment — Atomic purpose: atomic pairwise row binding one Tag to
# one Supplier, recording which tag key/values apply to the supplier.
#
# Why it exists: tags drive the ABAC permission engine (see docs/ABAC.md); this
# table records WHICH tag key/values apply to a supplier, replacing the old
# polymorphic tag_appointments table with concrete FKs.
# How it works: never create rows directly — call
# `supplier.attach_tag(key:, value:, description:)` (see TagConcern); read via
# `supplier.tags`. company_id derives from the tagged record via
# SetDefaultCompanyConcern.
# Main associations: belongs_to :company, :supplier, :tag (all required).
class SupplierTagAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :supplier
  belongs_to :tag
end
