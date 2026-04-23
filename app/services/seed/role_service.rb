class Seed::RoleService
  def self.new(
    company:,
    name:,
    description: nil,
    business_type: nil,
    discarded_at: nil
  )
    business_type ||= Role.business_types.keys.sample

    Role.new(
      company: company,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    role = new(...)
    role.save!
    role
  end
end
