class CompanyTicketComment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # NOTE: built-in Active Storage slots (not the shared FileAttachmentConcern —
  # comments take at most ONE image XOR ONE file, so the ticket's has_many
  # contract does not apply). Images are served via the :display variant.
  has_one_attached :image_attachment, dependent: :purge_later do |attachable|
    attachable.variant :display, resize_to_limit: TICKET_COMMENT_IMAGE_DIMENSIONS
  end
  has_one_attached :file_attachment, dependent: :purge_later

  # --- Associations ---
  belongs_to :company
  belongs_to :company_ticket
  belongs_to :author, polymorphic: true

  # --- Validations ---
  validates :message, presence: true
  validate :author_must_be_employee_or_user
  validate :author_in_ticket_company
  validate :ticket_same_company
  validate :acceptable_image_attachment
  validate :acceptable_file_attachment
  validate :only_one_attachment

  after_create :stamp_first_response_and_log

  def self.create_for!(ticket:, author:, message:, files: [])
    comment = new(company: ticket.company, company_ticket: ticket, author: author, message: message)
    Array(files).reject(&:blank?).each { |f| comment.attach_routed(f) } if files.present?
    comment.save!
    comment
  end

  # Single upload entry point shared by create_for!: routes each file to its
  # slot by MIME. Unknown types land in file_attachment so the type validation
  # rejects them with a clear message. has_one replaces silently, so filling
  # an occupied slot (or a second file) raises instead — the 422 contract holds.
  def attach_routed(file)
    content_type = routed_content_type(file)
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

  def routed_content_type(file)
    return file[:content_type] || file["content_type"] if file.is_a?(Hash)

    file.try(:content_type) || infer_content_type(file)
  end

  def infer_content_type(file)
    return unless file.respond_to?(:path) && file.path.present? && File.exist?(file.path)

    Marcel::MimeType.for(Pathname.new(file.path))
  end

  def acceptable_image_attachment
    return unless image_attachment.attached?

    unless ACCEPTABLE_TICKET_COMMENT_IMAGE_TYPES.include?(image_attachment.blob.content_type)
      errors.add(:image_attachment, "must be a PNG or JPEG image")
    end

    unless image_attachment.blob.byte_size <= MAX_TICKET_COMMENT_IMAGE_SIZE
      errors.add(:image_attachment, "is too big (max #{MAX_TICKET_COMMENT_IMAGE_SIZE / 1.megabyte}MB)")
    end
  end

  def acceptable_file_attachment
    return unless file_attachment.attached?

    unless ACCEPTABLE_TICKET_COMMENT_FILE_TYPES.include?(file_attachment.blob.content_type)
      errors.add(:file_attachment, "must be an Excel file")
    end

    unless file_attachment.blob.byte_size <= MAX_TICKET_COMMENT_FILE_SIZE
      errors.add(:file_attachment, "is too big (max #{MAX_TICKET_COMMENT_FILE_SIZE / 1.megabyte}MB)")
    end
  end

  def only_one_attachment
    if image_attachment.attached? && file_attachment.attached?
      errors.add(:base, "Attach either an image or a file, not both")
    end
  end

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
