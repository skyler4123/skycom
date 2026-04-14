class Seed::UserService
  def self.create(
    parent_user: nil,
    email: "user_#{SecureRandom.hex}@gmail.com",
    password: "Password@1234",
    password_confirmation: "Password@1234",
    verified: true,
    system_role:,
    username: Faker::Internet.unique.username(specifier: 5..8),
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    phone_number: Faker::PhoneNumber.phone_number,
    country_code: User.country_codes.keys.sample,
    index: nil
  )
    email ||= "#{email}#{index}@example.com"
    user = User.create!(
      parent_user: parent_user,
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      system_role: system_role,
      username: username,
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      country_code: country_code,
      verified: verified
    )
    Seed::AttachmentService.attach(record: user, relation: :avatar_attachment, number: 1)
    user
  end
end
