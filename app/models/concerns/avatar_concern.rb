module AvatarConcern
  extend ActiveSupport::Concern

  included do
    # This works for any model including this concern
    has_one_attached :avatar_attachment, dependent: :purge_later do |attachable|
      attachable.variant :thumb, resize_to_limit: [50, 50]
      attachable.variant :medium, resize_to_limit: [150, 150]
      attachable.variant :profile, resize_to_limit: [300, 300]
      attachable.variant :card, resize_to_fill: [400, 250] # For things like Company Headers
      attachable.variant :full, resize_to_limit: [1200, 1200]
    end

    def avatar_url(variant = :profile)
      return default_avatar_path unless avatar_attachment.attached?
      
      Rails.application.routes.url_helpers.rails_representation_url(
        avatar_attachment.variant(variant).processed, 
        only_path: true
      )
    rescue
      # Fallback to the original blob if processing is still pending
      Rails.application.routes.url_helpers.rails_blob_path(avatar_attachment, only_path: true)
    end

    private

    def default_avatar_path
      # You could return a specific placeholder based on the class name
      # e.g., "placeholders/company.png" vs "placeholders/user.png"
      "/placeholders/default.png"
    end
  end
end