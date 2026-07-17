class Seed::PageService
  CODE_PREFIXES = {
    cashier: "CSH",
    store_manager: "MGR"
  }.freeze

  def self.new(
    company:,
    branch:,
    name: "",
    description: nil,
    code: nil,
    business_type: :retail,
    target_role:,
    target_resolution: :desktop_widescreen,
    metadata: {},
    lifecycle_status: :active,
    workflow_status: :approved,
    permission_resource_name: "Page"
  )
    description ||= "#{name} page for #{branch.name}"
    code ||= "#{CODE_PREFIXES[target_role.to_s.delete_prefix("retail_").to_sym]}-#{branch.id&.first(8)}-#{SecureRandom.hex(2).upcase}"

    Page.new(
      company: company,
      branch: branch,
      name: name,
      description: description,
      code: code,
      business_type: business_type,
      target_role: target_role,
      target_resolution: target_resolution,
      metadata: metadata,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      permission_resource_name: permission_resource_name
    )
  end

  def self.create(...)
    page = new(...)
    page.save!
    page
  end
end
