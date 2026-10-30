# frozen_string_literal: true

# AvatarConcern — Atomic purpose: shared avatar attachment, variants, and URL
# helper for user-like records.
#
# Why it exists: avatar handling is identical across user-like models (one
# avatar, multiple variants, default placeholder), so the behavior lives here.
# How it works: adds has_one_attached :avatar_attachment with thumb/medium/
# profile/card/full variants and exposes #avatar_url(variant) with a placeholder
# fallback when no file is attached.
# Main associations: none directly; adds has_one_attached :avatar_attachment to
# includers.
module AvatarConcern
  extend ActiveSupport::Concern

  AVATAR_CARD_DIMENSIONS = [ 400, 250 ].freeze
  AVATAR_COMMON_FULL_DIMENSIONS = [ 1200, 1200 ].freeze

  included do
    has_one_attached :avatar_attachment, dependent: :purge_later do |attachable|
      attachable.variant :thumb, resize_to_limit: AVATAR_THUMB_DIMENSIONS
      attachable.variant :medium, resize_to_limit: AVATAR_MEDIUM_DIMENSIONS
      attachable.variant :profile, resize_to_limit: AVATAR_PROFILE_DIMENSIONS
      attachable.variant :card, resize_to_fill: AVATAR_CARD_DIMENSIONS
      attachable.variant :full, resize_to_limit: AVATAR_COMMON_FULL_DIMENSIONS
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
