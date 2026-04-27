class Seed::UserService
  def self.new(
    parent_user: nil,
    email: "user_#{SecureRandom.hex}@gmail.com",
    password: "Password@1234",
    password_confirmation: "Password@1234",
    verified: true,
    system_role:,
    username: Faker::Internet.unique.username(specifier: 5..8),
    name: nil,
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    phone_number: Faker::PhoneNumber.phone_number,
    country_code: User.country_codes.keys.sample,
    index: nil
  )
    email ||= "#{email}#{index}@example.com"
    User.new(
      parent_user: parent_user,
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      system_role: system_role,
      username: username,
      name: name || "#{first_name} #{last_name} #{SecureRandom.hex(4)}",
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      country_code: country_code,
      verified: verified
    )
  end

  def self.create(...)
    user = new(...)
    user.save!
    Seed::AttachmentService.attach(record: user, relation: :avatar_attachment, number: 1)
    user
  end
end
