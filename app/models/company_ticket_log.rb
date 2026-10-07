class CompanyTicketLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :action, {
    created: 0,
    assigned: 1,
    status_changed: 2,
    commented: 3,
    rated: 4
  }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :company_ticket
  belongs_to :actor, polymorphic: true, optional: true

  # --- Validations ---
  validates :action, presence: true
  validate :actor_must_be_employee_or_user_or_nil

  def self.record!(ticket:, action:, actor: nil, from_status: nil, to_status: nil, note: nil)
    create!(
      company: ticket.company,
      company_ticket: ticket,
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
