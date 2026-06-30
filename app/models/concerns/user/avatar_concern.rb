module User::AvatarConcern
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar_attachment, dependent: :purge_later do |attachable|
      attachable.variant :thumb, resize_to_limit: AVATAR_THUMB_DIMENSIONS
      attachable.variant :medium, resize_to_limit: AVATAR_MEDIUM_DIMENSIONS
      attachable.variant :profile, resize_to_limit: AVATAR_PROFILE_DIMENSIONS
      attachable.variant :full, resize_to_limit: AVATAR_FULL_DIMENSIONS
    end

    validate :acceptable_avatar_attachment

    def acceptable_avatar_attachment
      return unless avatar_attachment.attached?
      unless avatar_attachment.blob.byte_size <= MAX_AVATAR_FILE_SIZE
        errors.add(:avatar_attachment, "is too big (#{MAX_AVATAR_FILE_SIZE / 1.kilobyte}KB)")
      end

      unless ACCEPTABLE_AVATAR_TYPES.include?(avatar_attachment.content_type)
        errors.add(:avatar_attachment, "must be a JPEG or PNG")
      end
    end

    def avatar_url(variant = :profile)
      return "" unless avatar_attachment.attached?

      # Generates a URL for a specific variant
      Rails.application.routes.url_helpers.rails_representation_url(
        avatar_attachment.variant(variant).processed,
        only_path: true
      )
    rescue
      # Fallback if processing fails
      Rails.application.routes.url_helpers.rails_blob_path(avatar_attachment, only_path: true)
    end

    def update_avatar
      self.update(avatar: avatar_url)
    end
  end
end
