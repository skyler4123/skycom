module Brand::ImageConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :image_attachments, dependent: :purge_later do |attachable|
      attachable.variant :full, resize_to_limit: IMAGE_FULL_DIMENSIONS
      attachable.variant :thumb, resize_to_limit: IMAGE_THUMB_DIMENSIONS
    end

    validate :acceptable_image_attachments

    def acceptable_image_attachments
      return unless image_attachments.attached?

      if image_attachments.length > MAX_IMAGE_ATTACHMENTS
        errors.add(:image_attachments, "cannot have more than #{MAX_IMAGE_ATTACHMENTS} images")
      end

      image_attachments.each do |image|
        unless image.blob.byte_size <= MAX_IMAGE_FILE_SIZE
          errors.add(:image_attachments, "contains a file that is too big (max #{MAX_IMAGE_FILE_SIZE / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_IMAGE_TYPES.include?(image.content_type)
          errors.add(:image_attachments, "must be JPEG, PNG, or GIF")
        end
      end
    end

    def image_urls
      image_attachments.map do |attachment|
        Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
      end
    end
  end
end
