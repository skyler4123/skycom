# app/controllers/users/avatar_concern.rb
#
# Users::AvatarConcern — updates the signed-in user's avatar from a multipart
# upload. Shared by every page that renders the editable avatar() helper.
# Serves Stimulus: avatar_controller (web employee profile, mobile profile)
# Endpoints: PATCH /users/update_avatar (multipart: user[avatar_attachment])
# Docs: docs/AVATAR.md, docs/MOBILE.md
module Users::AvatarConcern
  extend ActiveSupport::Concern

  included do
    def update_avatar
      if current_user.update(avatar_params)
        current_user.update_avatar
        render json: {
          url: current_user.avatar_url(:profile),
          message: "Avatar updated!"
        }
      else
        render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
      end
    end

    private

    def avatar_params
      params.require(:user).permit(:avatar_attachment)
    end
  end
end
