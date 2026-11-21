# frozen_string_literal: true

# AttendanceLog — Atomic purpose: one raw check-in or check-out event for an
# employee.
#
# Why it exists: keeps the event stream that AttendanceDay aggregates; each row
# records exactly one punch with its timestamp.
# How it works: belongs to company/branch/employee; log_type is check_in or
# check_out, and logged_at is required. Optional latitude/longitude plus the
# gps_accuracy_meters and geofence_distance_meters metadata fields preserve the
# location evidence for a mobile punch. Day/month summaries are derived from
# these rows.
# Main associations: belongs_to :company, :employee (required), :branch (optional).
class AttendanceLog < ApplicationRecord
  store_accessor :metadata, :gps_accuracy_meters, :geofence_distance_meters

  enum :log_type, { check_in: 0, check_out: 1 }, prefix: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee

  validates :log_type, :logged_at, presence: true
end
