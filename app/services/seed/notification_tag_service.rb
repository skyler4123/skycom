class Seed::NotificationTagService
  # Single-file constant: only used here (see docs/CONSTANTS.md).
  FIXED_TAGS = {
    NotificationTag::OWNER_TAG_NAME => "Messages for the company owner.",
    NotificationTag::ALL_EMPLOYEES_TAG_NAME => "Broadcasts to every employee in the company."
  }.freeze

  def self.create_defaults!(company:)
    FIXED_TAGS.each do |name, description|
      NotificationTag.find_or_create_by!(company: company, name: name) do |tag|
        tag.description = description
        tag.business_type = :system
      end
    end

    # Per-role "All <Role>" tags are owned by Role callbacks
    # (after_create/after_update/before_destroy) — every role created via
    # create_roles or Seed::RoleService already has its tag by the time this
    # runs. This backfill heals companies whose roles predate the callbacks.
    company.roles.where.not(name: OWNER_BUSINESS_TYPE).find_each do |role|
      NotificationTag.find_or_create_by!(company: company, name: role.paired_tag_name) do |tag|
        tag.description = "Broadcasts to all employees with the #{role.name} role."
        tag.business_type = :system
      end
    end
  end
end
