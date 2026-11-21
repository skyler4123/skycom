# frozen_string_literal: true

# Booking::Status — the one derivation of a booking's live state for the
# Booking console. Wire values stay UTC; `now` is supplied by the caller so
# the server payload and the browser needle agree.
#
#   cancelled   → never shown
#   done        → workflow completed, or its end has passed
#   in_progress → workflow in progress (even if checked in early), or now is
#                 inside the booking window
#   upcoming    → everything else
# Docs: docs/OPERATIONS.md §7
module Booking
  module Status
    module_function

    def for(event, now:)
      return "cancelled" if event.workflow_status_cancelled?
      return "done" if event.workflow_status_completed?
      return "done" if event.end_at.present? && event.end_at <= now
      return "in_progress" if event.workflow_status_in_progress?
      return "in_progress" if event.start_at.present? && event.start_at <= now &&
        event.end_at.present? && event.end_at > now

      "upcoming"
    end
  end
end
