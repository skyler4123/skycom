class Seed::PageService
  CODE_PREFIXES = {
    retail_cashier: "RCSH",
    retail_store_manager: "RMGR",
    restaurant_cashier: "RSCSH",
    restaurant_waiter: "RSWT",
    restaurant_kitchen_staff: "RSKT",
    hospital_receptionist: "HPRC",
    hospital_doctor: "HPDR",
    hospital_nurse: "HPNR",
    education_receptionist: "EDRC",
    education_teacher: "EDTC",
    education_manager: "EDMG",
    hotel_receptionist: "HTRC",
    hotel_housekeeping: "HTHK",
    hotel_manager: "HTMG",
    fitness_receptionist: "FTRC",
    fitness_trainer: "FTTR",
    fitness_manager: "FTMG"
  }.freeze

  def self.new(
    company:,
    branch:,
    name: nil,
    description: nil,
    code: nil,
    business_type: nil,
    target_role:,
    target_resolution: :desktop,
    metadata: {},
    lifecycle_status: :active,
    workflow_status: :approved,
    permission_resource_name: "Page"
  )
    business_type ||= company.business_type
    name ||= Page.default_name_for(
      business_type: business_type,
      target_role: target_role,
      target_resolution: target_resolution
    ) || target_role.to_s.titleize
    description ||= "#{name} page for #{branch.name}"
    code ||= "#{CODE_PREFIXES.fetch(target_role.to_sym, "PG")}-#{branch.id&.first(8)}-#{SecureRandom.hex(2).upcase}"

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

  # Idempotently creates every page type in the company's catalog for a branch,
  # once per target resolution. Safe to call repeatedly.
  def self.ensure_defaults_for_branch!(branch)
    company = branch.company
    return [] if company.blank?

    Page.target_roles_for(company.business_type).flat_map do |target_role|
      Page.target_resolutions.keys.map do |target_resolution|
        page = Page.find_or_initialize_by(
          company: company,
          branch: branch,
          target_role: target_role,
          target_resolution: target_resolution
        )

        if page.new_record?
          page.assign_attributes(
            name: Page.default_name_for(
              business_type: company.business_type,
              target_role: target_role,
              target_resolution: target_resolution
            ),
            description: "#{company.business_type.humanize} page for #{branch.name}",
            business_type: company.business_type,
            metadata: {},
            lifecycle_status: :active,
            workflow_status: :approved,
            permission_resource_name: "Page"
          )
          page.code ||= "#{CODE_PREFIXES.fetch(target_role.to_sym, "PG")}-#{branch.id&.first(8)}-#{SecureRandom.hex(2).upcase}"
          page.save!
        end

        page
      end
    end
  end
end
