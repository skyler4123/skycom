class Seed::UserService
  def self.run
    User.destroy_all

    self.create_demo_user
  end

  def self.create_demo_user
    10.times do |n|
      user = User.create!(
        email: "user#{n}@example.com",
        password: "Password@1234",
        password_confirmation: "Password@1234",
        verified: true
      )
    end
  end
end
