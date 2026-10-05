class Seed::ChatUserService
  def self.mirror_subset!(users:)
    users.map { |user| ChatUser.sync_from_user!(user) }
  end
end
