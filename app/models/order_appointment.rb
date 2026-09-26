class OrderAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  # The exact Stock row this line was reserved against (set at POS pay time,
  # read at finalize). Makes finalize warehouse-deterministic — docs/
  # superpowers/specs/2026-09-23-stock-source-of-truth-design.md §5.
  store_accessor :metadata, :stock_id

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :order
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true
end
