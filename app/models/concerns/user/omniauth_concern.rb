module User::OmniauthConcern
  extend ActiveSupport::Concern

  included do
    def self.from_omniauth(auth_data)
      # Find existing user or initialize a new one
      user = find_by(provider: auth_data.provider, uid: auth_data.uid) || find_by(email: auth_data.info.email)

      if user.nil?
        user = User.new(
          provider: auth_data.provider,
          uid: auth_data.uid,
          email: auth_data.info.email,
          verified: true, # Google emails are pre-verified
          system_role: :company_employee,
          country: "vn"
        )
      else
        # Ensure provider and uid are synced if they logged in via email previously
        user.provider ||= auth_data.provider
        user.uid ||= auth_data.uid
      end

      # Update dynamic profile information on every login
      user.name = auth_data.info.name
      user.first_name = auth_data.info.first_name
      user.last_name = auth_data.info.last_name

      # Generate unique username matching your template if it's a new record
      if user.username.blank?
        user.username = "#{auth_data.info.first_name.downcase}_#{SecureRandom.hex(4)}"
      end

      # If your password_digest is required, provide a random fallback for OAuth accounts
      if user.password_digest.blank?
        user.password = SecureRandom.hex(16)
      end

      user.save
      user
    end
  end
end
