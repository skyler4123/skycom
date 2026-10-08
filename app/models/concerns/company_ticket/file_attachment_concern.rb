module CompanyTicket::FileAttachmentConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :file_attachments, dependent: :purge_later

    validate :acceptable_file_attachments

    def acceptable_file_attachments
      return unless file_attachments.attached?

      if file_attachments.length > MAX_TICKET_ATTACHMENTS
        errors.add(:file_attachments, "cannot have more than #{MAX_TICKET_ATTACHMENTS} files")
      end

      file_attachments.each do |file|
        unless file.blob.byte_size <= MAX_TICKET_FILE_SIZE
          errors.add(:file_attachments, "contains a file that is too big (max #{MAX_TICKET_FILE_SIZE / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_TICKET_FILE_TYPES.include?(file.blob.content_type)
          errors.add(:file_attachments, "must be an image, PDF, text, Word or Excel file")
        end
      end
    end

    def file_attachment_urls
      file_attachments.map do |attachment|
        Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
      end
    end
  end
end
