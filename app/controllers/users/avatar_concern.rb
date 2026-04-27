# app/controllers/users/avatar_concern.rb

module Users::AvatarConcern
  extend ActiveSupport::Concern

  included do
    def update_avatar
      if current_user.update(avatar_params)
        current_user.update_avatar
        current_user.refresh_cache
        render json: { 
          url: current_user.avatar_url(:profile),
          message: "Avatar updated!" 
        }
      else
        render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def avatar_params
      params.require(:user).permit(:avatar_attachment)
    end
  end
end
