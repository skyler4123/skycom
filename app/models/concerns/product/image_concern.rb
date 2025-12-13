module Product::ImageConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :image_attachments, dependent: :purge_later do |attachable|
      attachable.variant :full, resize_to_limit: [ 300, 300 ]
      attachable.variant :thumb, resize_to_limit: [ 50, 50 ]
    end

    validate :acceptable_image_attachments

    def acceptable_image_attachments
      return unless image_attachments.attached?

      if image_attachments.length > 3
        errors.add(:image_attachments, "cannot have more than 3 images")
      end

      image_attachments.each do |image|
        # Check size (e.g., 1MB limit for chat images, or keep 200KB if strict)
        unless image.blob.byte_size <= 1.megabyte
          errors.add(:image_attachments, "contains a file that is too big (max 1MB)")
        end

        # Check content type
        acceptable_types = [ "image/jpeg", "image/png", "image/gif" ]
        unless acceptable_types.include?(image.content_type)
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
