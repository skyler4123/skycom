module User::ChatImagesConcern
  extend ActiveSupport::Concern

  included do
    has_many_attached :chat_image_attachments, dependent: :purge_later do |attachable|
      attachable.variant :full, resize_to_limit: [ 300, 300 ]
      attachable.variant :thumb, resize_to_limit: [ 50, 50 ]
    end

    validate :acceptable_chat_image_attachments

    # --- Validation Logic for Many Attachments ---
    def acceptable_chat_image_attachments
      return unless chat_image_attachments.attached?

      chat_image_attachments.each do |image|
        # Check size (e.g., 1MB limit for chat images, or keep 200KB if strict)
        unless image.blob.byte_size <= 1.megabyte
          errors.add(:chat_image_attachments, "contains a file that is too big (max 1MB)")
        end

        # Check content type
        acceptable_types = [ "image/jpeg", "image/png", "image/gif" ]
        unless acceptable_types.include?(image.content_type)
          errors.add(:chat_image_attachments, "must be JPEG, PNG, or GIF")
        end
      end
    end
  end
end
