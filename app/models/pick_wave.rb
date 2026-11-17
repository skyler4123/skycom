# frozen_string_literal: true

# PickWave — Atomic purpose: a batch of orders released to the warehouse floor to be picked together.
#
# Why it exists: picking one order at a time doubles the walking distance and makes labour planning impossible; a wave is the unit a supervisor releases, assigns and measures, and it is the only place to hang 'these 40 orders are being picked now'.
# How it works: header with a status and timestamps; member orders join through OrderPickWaveAppointment; the actual work items are PickTasks. Releasing a wave is the point of no return for its orders, so the status transition is explicit.
# Main associations: belongs_to :company, :warehouse, :created_by_employee (optional); has_many :order_pick_wave_appointments, :pick_tasks.
class PickWave < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :warehouse
  belongs_to :created_by_employee, class_name: "Employee", optional: true
  has_many :order_pick_wave_appointments, dependent: :destroy
  has_many :orders, through: :order_pick_wave_appointments
  has_many :pick_tasks, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
end
