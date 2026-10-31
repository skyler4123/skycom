# frozen_string_literal: true

# CompanyTicket — Atomic purpose: support ticket raised by a company employee to
# the Skycom platform team.
#
# Why it exists: tenant support needs a separate queue, SLA timestamps,
# assignment to Skycom staff, comments, and an audit log; it is distinct from
# internal employee Tickets (see docs/TICKET.md).
# How it works: belongs to company/employee and optional assigned_user (staff
# admin/super_admin); status drives workflow_status mirroring and resolved_at;
# assign_to!/transition_to!/rate! write CompanyTicketLog rows and invalidate the
# open-count cache.
# Main associations: belongs_to :company, :employee (required), :assigned_user
# (optional); has_many :ticket_comments (CompanyTicketComment), :ticket_logs
# (CompanyTicketLog) (dependent: :destroy).
class CompanyTicket < ApplicationRecord
  include CompanyTicket::FileAttachmentConcern

  class AlreadyAssigned < StandardError; end
  class NotTicketOwner < StandardError; end

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :ticket_category, {
    billing: 0,
    technical: 1,
    account: 2,
    feature_request: 3,
    other: 4
  }
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }, prefix: true, default: :medium
  enum :status, {
    open: 0,
    in_progress: 1,
    waiting_customer: 2,
    resolved: 3,
    closed: 4,
    cancelled: 5
  }, prefix: true, default: :open
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :assigned_user, class_name: "User", optional: true
  has_many :ticket_comments, class_name: "CompanyTicketComment", dependent: :destroy
  has_many :ticket_logs, class_name: "CompanyTicketLog", dependent: :destroy

  # --- Scopes ---
  scope :open_tickets, -> { where(status: %i[open in_progress waiting_customer]) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :ticket_category, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :rate, inclusion: { in: 1..5 }, allow_nil: true
  validate :rate_only_after_resolution
  validate :assignee_must_be_staff

  before_validation :mirror_workflow_status
  before_update :stamp_sla_timestamps
  after_create :log_created
  after_create :invalidate_count_caches

  def assign_to!(user, actor: nil)
    with_lock do
      if assigned_user_id.present? && assigned_user_id != user.id
        raise AlreadyAssigned, "ticket is already assigned"
      end
      return true if assigned_user_id == user.id

      update!(assigned_user: user)
      CompanyTicketLog.record!(ticket: self, action: :assigned, actor: actor,
        note: "assigned to #{user.email}")
      invalidate_count_caches
      true
    end
  end

  def transition_to!(new_status, actor: nil, note: nil)
    with_lock do
      from = status
      update!(status: new_status)
      CompanyTicketLog.record!(ticket: self, action: :status_changed, actor: actor,
        from_status: from, to_status: status, note: note)
      invalidate_count_caches
      true
    end
  end

  def rate!(value, employee:)
    raise NotTicketOwner, "only the ticket creator can rate" unless employee.id == employee_id

    with_lock do
      update!(rate: value)
      CompanyTicketLog.record!(ticket: self, action: :rated, actor: employee)
      true
    end
  end

  private

  def mirror_workflow_status
    self.workflow_status = case status
    when "open" then "pending"
    when "in_progress" then "in_progress"
    when "waiting_customer" then "confirmed"
    when "resolved", "closed" then "completed"
    when "cancelled" then "cancelled"
    end
  end

  def stamp_sla_timestamps
    if status_resolved? || status_closed?
      self.resolved_at ||= Time.current
    else
      self.resolved_at = nil
    end
  end

  def log_created
    CompanyTicketLog.record!(ticket: self, action: :created, actor: employee)
  end

  def invalidate_count_caches
    Rails.sync_cache.delete(CacheKeyService.company_open_ticket_count(company_id))
    Rails.sync_cache.delete(CacheKeyService.admin_open_ticket_count)
  end

  def rate_only_after_resolution
    return if rate.nil?
    return if status_resolved? || status_closed?

    errors.add(:rate, "can only be set on resolved or closed tickets")
  end

  def assignee_must_be_staff
    return if assigned_user.nil?
    return if assigned_user.system_role_admin? || assigned_user.system_role_super_admin?

    errors.add(:assigned_user, "must be Skycom staff")
  end
end
