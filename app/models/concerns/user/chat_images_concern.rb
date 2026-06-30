module User::ChatImagesConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :chat_image_attachments, dependent: :purge_later do |attachable|
      attachable.variant :full, resize_to_limit: IMAGE_FULL_DIMENSIONS
      attachable.variant :thumb, resize_to_limit: IMAGE_THUMB_DIMENSIONS
    end

    validate :acceptable_chat_image_attachments

    # --- Validation Logic for Many Attachments ---
    def acceptable_chat_image_attachments
      return unless chat_image_attachments.attached?

      chat_image_attachments.each do |image|
        unless image.blob.byte_size <= MAX_IMAGE_FILE_SIZE
          errors.add(:chat_image_attachments, "contains a file that is too big (max #{MAX_IMAGE_FILE_SIZE / 1.megabyte}MB)")
        end

        unless ACCEPTABLE_IMAGE_TYPES.include?(image.content_type)
          errors.add(:chat_image_attachments, "must be JPEG, PNG, or GIF")
        end
      end
    end
  end
end
