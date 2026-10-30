# frozen_string_literal: true

# AttendanceConfig — Atomic purpose: per-branch attendance rules (geofence, photo
# requirement, check-in/check-out strategy).
#
# Why it exists: attendance capture must be validated against a branch location
# and policy; one config row per branch makes those rules explicit.
# How it works: belongs to a company and branch; latitude/longitude define the
# allowed geofence (allowed_radius_meters), require_photo toggles photo proof, and
# resolution_strategy selects check_in_only vs paired. Changes are audited in
# AttendanceConfigLog.
# Main associations: belongs_to :company, :branch (required); has_many
# :attendance_config_logs (dependent: :nullify).
class AttendanceConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :allowed_radius_meters, :integer, default: 100
  attribute :require_photo, :boolean, default: false

  enum :resolution_strategy, {  check_in_only: 0, paired: 1 }, prefix: true, default: :check_in_only
  belongs_to :company
  belongs_to :branch

  has_many :attendance_config_logs, dependent: :nullify

  validates :latitude, :longitude, presence: true
end
