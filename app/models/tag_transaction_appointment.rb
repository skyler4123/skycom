class TagTransactionAppointment < ApplicationRecord
  # Tag assignment — atomic pairwise row binding one Tag to its tagged record.
  #
  # Why it exists: tags drive the ABAC permission engine (see docs/ABAC.md); this
  # table records WHICH tag key/values apply to a record, replacing the old
  # polymorphic tag_appointments table.
  # How to use: never create rows directly — call
  # `record.attach_tag(key:, value:, description:)` (see TagConcern); read via
  # `record.tags`.
  # How it works: table/association names follow the alphabetical pair order —
  # "Tag" sorts before Task/TaskGroup/Transaction/Warehouse, so this table is
  # Tag-first. company_id derives from the tagged record via
  # SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :tag
  # `transaction` conflicts with ActiveRecord#transaction, so use explicit name.
  belongs_to :target_transaction, class_name: "Transaction", foreign_key: "transaction_id"
end
