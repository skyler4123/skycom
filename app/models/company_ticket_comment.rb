class CompanyTicketComment < ApplicationRecord
  include CompanyTicket::FileAttachmentConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :company_ticket
  belongs_to :author, polymorphic: true

  # --- Validations ---
  validates :message, presence: true
  validate :author_must_be_employee_or_user
  validate :author_in_ticket_company
  validate :ticket_same_company

  after_create :stamp_first_response_and_log

  def self.create_for!(ticket:, author:, message:, files: [])
    comment = new(company: ticket.company, company_ticket: ticket, author: author, message: message)
    Array(files).each { |f| comment.file_attachments.attach(f) } if files.present?
    comment.save!
    comment
  end

  private

  def stamp_first_response_and_log
    if author_type == "User" && company_ticket.first_responded_at.nil?
      company_ticket.update!(first_responded_at: Time.current)
    end
    CompanyTicketLog.record!(ticket: company_ticket, action: :commented, actor: author)
  end

  def author_must_be_employee_or_user
    return if %w[Employee User].include?(author_type)

    errors.add(:author, "must be an Employee or User")
  end

  def author_in_ticket_company
    return unless author_type == "Employee" && author && company_ticket

    if author.company_id != company_ticket.company_id
      errors.add(:author, "must belong to the ticket's company")
    end
  end

  def ticket_same_company
    return if company_id.nil? || company_ticket.nil?

    if company_id != company_ticket.company_id
      errors.add(:company_ticket, "must belong to the same company")
    end
  end
end
