# frozen_string_literal: true

# DisbursementBatch — Atomic purpose: one run of outgoing salary payments (the bank file and its totals) for a payment date.
#
# Why it exists: payroll approval and payroll payment are different events: the bank needs one file per payment date, the accountant needs one journal entry, and the company needs proof of what was actually transferred. A batch row is that unit, so a failed transfer is retried as a batch instead of per employee.
# How it works: groups payroll rows for a payment date, carries the derived total and the generated file, and moves through a status enum. Payrolls point at the batch; the file itself is a StoredFile so it shares the existing storage, download and permission paths.
# Main associations: belongs_to :company, :branch (optional), :stored_file (optional); has_many :payrolls.
class DisbursementBatch < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, DISBURSEMENT_BATCH_STATUSES, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :stored_file, optional: true
  has_many :payrolls, dependent: :nullify

  # --- Scopes ---
  scope :for_payment_on, ->(date) { where(payment_on: date) }
  scope :ordered, -> { order(payment_on: :desc) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :payment_on, presence: true
  validates :total_cents, numericality: { only_integer: true }

  # --- Methods ---
  def recompute_total!
    update!(total_cents: payrolls.sum(:net_amount_cents))
  end
end
