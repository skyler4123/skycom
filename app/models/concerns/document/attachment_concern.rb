module Document::AttachmentConcern
  extend ActiveSupport::Concern

  DOCUMENT_MAX_IMAGES = 10
  DOCUMENT_MAX_IMAGE_SIZE = 1.megabyte
  DOCUMENT_MAX_FILES = 5
  DOCUMENT_MAX_FILE_SIZE = 5.megabytes

  included do
    has_many_attached :image_attachments, dependent: :purge_later do |attachable|
      attachable.variant :full, resize_to_limit: IMAGE_FULL_DIMENSIONS
      attachable.variant :thumb, resize_to_limit: IMAGE_THUMB_DIMENSIONS
    end
    has_many_attached :file_attachments, dependent: :purge_later

    validate :acceptable_image_attachments
    validate :acceptable_file_attachments

    def acceptable_image_attachments
      return unless image_attachments.attached?

      if image_attachments.length > DOCUMENT_MAX_IMAGES
        errors.add(:image_attachments, "cannot have more than #{DOCUMENT_MAX_IMAGES} images")
      end

      image_attachments.each do |image|
        unless image.blob.byte_size <= DOCUMENT_MAX_IMAGE_SIZE
          errors.add(:image_attachments, "contains a file that is too big (max #{DOCUMENT_MAX_IMAGE_SIZE / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_IMAGE_TYPES.include?(image.content_type)
          errors.add(:image_attachments, "must be JPEG, PNG, or GIF")
        end
      end
    end

    def acceptable_file_attachments
      return unless file_attachments.attached?

      if file_attachments.length > DOCUMENT_MAX_FILES
        errors.add(:file_attachments, "cannot have more than #{DOCUMENT_MAX_FILES} files")
      end

      file_attachments.each do |file|
        unless file.blob.byte_size <= DOCUMENT_MAX_FILE_SIZE
          errors.add(:file_attachments, "contains a file that is too big (max #{DOCUMENT_MAX_FILE_SIZE / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_TICKET_FILE_TYPES.include?(file.content_type)
          errors.add(:file_attachments, "must be an image, text, PDF, Word, or Excel file")
        end
      end
    end

    def image_urls
      image_attachments.map do |attachment|
        {
          "id" => attachment.id,
          "filename" => attachment.filename.to_s,
          "url" => blob_path(attachment),
          "thumb_url" => thumb_path(attachment),
          "byte_size" => attachment.byte_size
        }
      end
    end

    def file_urls
      file_attachments.map do |attachment|
        {
          "id" => attachment.id,
          "filename" => attachment.filename.to_s,
          "url" => blob_path(attachment),
          "byte_size" => attachment.byte_size,
          "content_type" => attachment.content_type
        }
      end
    end

    private

    def blob_path(attachment)
      Rails.application.routes.url_helpers.rails_blob_path(
        attachment, only_path: true, disposition: "attachment"
      )
    end

    def thumb_path(attachment)
      Rails.application.routes.url_helpers.rails_representation_url(
        attachment.variant(:thumb).processed, only_path: true
      )
    rescue StandardError
      blob_path(attachment)
    end
  end
end
