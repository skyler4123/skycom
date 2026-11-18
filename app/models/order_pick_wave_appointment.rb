# frozen_string_literal: true

# OrderPickWaveAppointment — Atomic purpose: links one Order to the PickWave that is picking it.
#
# Why it exists: an order may be split across waves and a wave covers many orders; without the pair the wave cannot report which orders it contains and an order cannot answer 'who is picking me'.
# How it works: atomic pair, company derived from the order. Unique per (order, wave) so re-adding is idempotent.
# Main associations: belongs_to :company, :order, :pick_wave.
class OrderPickWaveAppointment < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :order
  belongs_to :pick_wave

  # --- Validations ---
  validates :order_id, uniqueness: { scope: :pick_wave_id }
end
