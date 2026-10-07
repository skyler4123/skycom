module CompanyTicket::FileAttachmentConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :file_attachments, dependent: :purge_later

    validate :acceptable_file_attachments

    def acceptable_file_attachments
      return unless file_attachments.attached?

      if file_attachments.length > attachment_limit
        errors.add(:file_attachments, "cannot have more than #{attachment_limit} #{attachment_limit == 1 ? 'file' : 'files'}")
      end

      file_attachments.each do |file|
        max_size = file.blob.content_type.to_s.start_with?("image/") ? attachment_image_max : attachment_file_max
        unless file.blob.byte_size <= max_size
          errors.add(:file_attachments, "contains a file that is too big (max #{max_size / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_TICKET_FILE_TYPES.include?(file.blob.content_type)
          errors.add(:file_attachments, "must be an image, PDF, text, Word or Excel file")
        end
      end
    end

    def attachment_limit
      instance_of?(CompanyTicketComment) ? MAX_TICKET_COMMENT_ATTACHMENTS : MAX_TICKET_ATTACHMENTS
    end

    def attachment_image_max
      instance_of?(CompanyTicketComment) ? MAX_TICKET_COMMENT_IMAGE_SIZE : MAX_TICKET_FILE_SIZE
    end

    def attachment_file_max
      instance_of?(CompanyTicketComment) ? MAX_TICKET_COMMENT_FILE_SIZE : MAX_TICKET_FILE_SIZE
    end

    def file_attachment_urls
      file_attachments.map do |attachment|
        Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
      end
    end
  end
end
