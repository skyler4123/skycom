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
    Array(files).reject(&:blank?).each { |f| comment.file_attachments.attach(prepared_upload(f)) } if files.present?
    comment.save!
    comment
  end

  # Downscale oversized comment images BEFORE attach so the 2MB original is
  # never persisted — blobs on a new record have no service file yet, so this
  # must run here (not in a validation callback). Fail-open: anything we cannot
  # read or resize is returned untouched and the size validation still caps it.
  def self.prepared_upload(file)
    filename = file.try(:original_filename) || (file.respond_to?(:path) ? File.basename(file.path) : "upload")
    source_path = (file.respond_to?(:path) && file.path.present? && File.exist?(file.path) ? file.path : nil)
    content_type = file.try(:content_type) ||
      (source_path ? Marcel::MimeType.for(Pathname.new(source_path)) : nil)
    return file unless content_type.to_s.start_with?("image/")
    return file unless ACCEPTABLE_TICKET_FILE_TYPES.include?(content_type)

    limit_w, limit_h = TICKET_COMMENT_IMAGE_DIMENSIONS
    tmp_in = nil
    unless source_path
      tmp_in = Tempfile.new([ "comment-in", File.extname(filename.to_s) ])
      tmp_in.binmode
      io = file.respond_to?(:read) ? file : file.open
      io.rewind if io.respond_to?(:rewind)
      tmp_in.write(io.read)
      tmp_in.flush
      source_path = tmp_in.path
    end

    image = MiniMagick::Image.open(source_path)
    return file if image.width <= limit_w && image.height <= limit_h

    processed = ImageProcessing::MiniMagick.source(source_path).resize_to_limit(limit_w, limit_h).call
    { io: File.open(processed.path, "rb"), filename: filename, content_type: content_type }
  rescue => e
    Rails.logger.warn("[TicketComment] downscale skipped: #{e.message}")
    file
  ensure
    tmp_in&.close!
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
