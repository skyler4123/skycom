class TicketComment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # Built-in Active Storage slots (single image XOR single file).
  has_one_attached :image_attachment, dependent: :purge_later do |attachable|
    attachable.variant :display, resize_to_limit: TICKET_COMMENT_IMAGE_DIMENSIONS rescue nil
  end
  has_one_attached :file_attachment, dependent: :purge_later

  # --- Associations ---
  belongs_to :company
  belongs_to :ticket
  belongs_to :employee

  # --- Validations ---
  validates :message, presence: true
  validate :employee_in_ticket_company
  validate :ticket_same_company

  after_create :stamp_log

  def self.create_for!(ticket:, employee:, message:, files: [])
    comment = new(company: ticket.company, ticket: ticket, employee: employee, message: message)
    Array(files).reject(&:blank?).each { |f| comment.attach_routed(f) } if files.present?
    comment.save!
    comment
  end

  def attach_routed(file)
    content_type = file.respond_to?(:content_type) ? file.content_type : (file.is_a?(Hash) ? (file[:content_type] || file["content_type"]) : nil)
    if content_type.to_s.start_with?("image/")
      raise ActiveRecord::RecordInvalid.new(self), "Cannot attach both an image and a file" if file_attachment.attached? || image_attachment.attached?
      image_attachment.attach(file)
    else
      raise ActiveRecord::RecordInvalid.new(self), "Cannot attach both an image and a file" if file_attachment.attached? || image_attachment.attached?
      file_attachment.attach(file)
    end
  end

  def display_attachments
    [ image_attachment, file_attachment ].select(&:attached?)
  end

  private

  def employee_in_ticket_company
    return unless employee && ticket
    if employee.company_id != ticket.company_id
      errors.add(:employee, "must belong to the ticket's company")
    end
  end

  def ticket_same_company
    return if company_id.nil? || ticket.nil?
    if company_id != ticket.company_id
      errors.add(:ticket, "must belong to the same company")
    end
  end

  def stamp_log
    TicketLog.record!(ticket: ticket, action: :commented, actor: employee)
  rescue StandardError
    nil
  end
end
