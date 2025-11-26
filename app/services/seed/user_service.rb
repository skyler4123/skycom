class Seed::UserService

  def self.run
    User.destroy_all

    3.times do |index|
      self.create(index: index)
    end

  end

  def self.create(
    parent_user: nil,
    email:,
    password: "Password@1234",
    password_confirmation: "Password@1234",
    verified: true,
    index: nil,
    company_business_type: nil
  )
    company_business_type ||= parent_user&.company_business_type
    email ||= "#{email}#{index}@example.com"
    user = User.create!(
      parent_user: parent_user,
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      verified: verified,
      company_business_type: company_business_type
    )
    Seed::AttachmentService.attach(record: user, relation: :avatar_attachment, number: 1)
    user
  end

end
