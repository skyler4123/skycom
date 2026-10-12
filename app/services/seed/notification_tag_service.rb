class Seed::NotificationTagService
  # Single-file constant: only used here (see docs/CONSTANTS.md).
  FIXED_TAGS = {
    "All Company" => "Broadcasts to every employee in the company.",
    "Promotion" => "Marketing and promotion campaigns."
  }.freeze

  def self.create_defaults!(company:)
    FIXED_TAGS.each do |name, description|
      NotificationTag.find_or_create_by!(company: company, name: name) do |tag|
        tag.description = description
        tag.business_type = :system
      end
    end

    company.roles.where.not(name: OWNER_BUSINESS_TYPE).find_each do |role|
      NotificationTag.find_or_create_by!(company: company, name: "All #{role.name}") do |tag|
        tag.description = "Broadcasts to all employees with the #{role.name} role."
        tag.business_type = :system
      end
    end
  end
end
