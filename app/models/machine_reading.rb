# frozen_string_literal: true

# MachineReading — Atomic purpose: one usage measurement from a machine or work center at a point in time.
#
# Why it exists: usage-based maintenance and machine utilisation both need a time series; a single 'hours run' counter can only answer today's question, and overwriting it destroys the history that Preventive maintenance intervals are computed from.
# How it works: append-only rows per work center with usage and output units. `recorded_at` is the measurement time. Aggregates are computed by query, never stored here.
# Main associations: belongs_to :company, :work_center.
class MachineReading < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :work_center

  # --- Scopes ---
  scope :between, ->(from, to) { where(recorded_at: from..to) }
end
