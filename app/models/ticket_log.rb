# frozen_string_literal: true

# TicketLog — Atomic purpose: append-only audit row for a Ticket event (created,
# assigned, commented, workflow_step_changed).
#
# Why it exists: keeps a readable activity history separate from the ticket and
# supports polymorphic actors (Employee or User).
# How it works: belongs to company/ticket and optional polymorphic actor; the
# class method record! is the single write path.
# Main associations: belongs_to :company, :ticket (required); belongs_to :actor,
# polymorphic: true (optional).
class TicketLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, {
    created: 0,
    assigned: 1,
    commented: 2,
    workflow_step_changed: 3
  }, prefix: true

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :ticket
  belongs_to :actor, polymorphic: true, optional: true

  # --- Validations ---
  validates :action, presence: true
  validate :actor_must_be_employee_or_user_or_nil

  def self.record!(ticket:, action:, actor: nil, from_status: nil, to_status: nil, note: nil)
    create!(
      company: ticket.company,
      ticket: ticket,
      actor: actor,
      action: action,
      from_status: from_status,
      to_status: to_status,
      note: note
    )
  end

  private

  def actor_must_be_employee_or_user_or_nil
    return if actor.nil?
    return if %w[Employee User].include?(actor_type)
    errors.add(:actor, "must be an Employee or User")
  end
end
