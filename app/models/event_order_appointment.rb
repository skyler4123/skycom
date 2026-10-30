# frozen_string_literal: true

# EventOrderAppointment — Atomic purpose: atomic join row binding exactly two
# records (Event ↔ Order).
#
# Why it exists: an Event tracks the occasion while an Order processes its
# payment — this row is the trace between them. Created once by
# Events::CreateOrderService when a completed event's category asks for an
# order; the order then flows through the normal POS pipeline untouched.
#
# How to use: read via event.event_order_appointments / order counterpart; never
# created by hand outside the bridge service.
#
# How it works: table and class names use the alphabetical pair order (Event <
# Order). company_id derives from either side via SetDefaultCompanyConcern.
#
# Main associations: belongs_to :company, :event, :order.
class EventOrderAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :event
  belongs_to :order
end
