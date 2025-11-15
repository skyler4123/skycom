class Seed::UserService
  def self.run
    User.destroy_all

    3.times do |index|
      self.create(index: index)
    end

  end

  def self.create(username: "user", index: "")
    User.create!(
      email: "#{username}#{index}@example.com",
      password: "Password@1234",
      password_confirmation: "Password@1234",
      verified: true
    )
  end
end
