class Seed::ConfigLogService
  # Seeds 2 audit rows (created + updated) per config so the read-only log
  # pages have demo data in development. Rows mirror what the controllers
  # write at runtime: full raw snapshot + actor employee + denormalized names.
  # Called once per company from Seed::ApplicationService after enrich.
  def self.seed_for(company:)
    employees = company.employees.to_a
    seed_event_config_logs(company, employees)
    seed_attendance_config_logs(company, employees)
    seed_table_config_logs(company, employees)
    seed_permission_logs(company, employees)
  end

  def self.seed_event_config_logs(company, employees)
    company.event_configs.find_each do |config|
      actor = employees.sample
      EventConfigLog.create!(
        company: company, event_config: config, category: config.category,
        employee: actor, employee_name: actor&.name, action: :created,
        category_name: config.category&.name,
        create_stock_pending: config.create_stock_pending,
        strict_stock_hold: config.strict_stock_hold,
        create_order_on_complete: config.create_order_on_complete,
        warn_on_facility_overlap: config.warn_on_facility_overlap,
        warn_on_host_overlap: config.warn_on_host_overlap,
        metadata: config.metadata, discarded_at: config.discarded_at,
        created_at: 6.days.ago, updated_at: 6.days.ago
      )
      updater = (employees - [ actor ]).sample || actor
      EventConfigLog.create!(
        company: company, event_config: config, category: config.category,
        employee: updater, employee_name: updater&.name, action: :updated,
        category_name: config.category&.name,
        create_stock_pending: config.create_stock_pending,
        strict_stock_hold: !config.strict_stock_hold,
        create_order_on_complete: config.create_order_on_complete,
        warn_on_facility_overlap: config.warn_on_facility_overlap,
        warn_on_host_overlap: config.warn_on_host_overlap,
        metadata: config.metadata, discarded_at: config.discarded_at,
        created_at: 2.days.ago, updated_at: 2.days.ago
      )
    end
  end

  def self.seed_attendance_config_logs(company, employees)
    company.attendance_configs.find_each do |config|
      actor = employees.sample
      AttendanceConfigLog.create!(
        company: company, attendance_config: config, branch: config.branch,
        employee: actor, employee_name: actor&.name, action: :created,
        branch_name: config.branch&.name,
        latitude: config.latitude, longitude: config.longitude,
        allowed_radius_meters: config.allowed_radius_meters,
        allowed_wifi_ssid: config.allowed_wifi_ssid,
        require_photo: config.require_photo,
        resolution_strategy: config.resolution_strategy,
        metadata: config.metadata, discarded_at: config.discarded_at,
        created_at: 6.days.ago, updated_at: 6.days.ago
      )
      updater = (employees - [ actor ]).sample || actor
      AttendanceConfigLog.create!(
        company: company, attendance_config: config, branch: config.branch,
        employee: updater, employee_name: updater&.name, action: :updated,
        branch_name: config.branch&.name,
        latitude: config.latitude, longitude: config.longitude,
        allowed_radius_meters: (config.allowed_radius_meters || 100) + 100,
        allowed_wifi_ssid: config.allowed_wifi_ssid,
        require_photo: config.require_photo,
        resolution_strategy: config.resolution_strategy,
        metadata: config.metadata, discarded_at: config.discarded_at,
        created_at: 2.days.ago, updated_at: 2.days.ago
      )
    end
  end

  def self.seed_permission_logs(company, employees)
    appointments = company.policy_role_appointments.includes(:role, :policy).limit(3).to_a
    return if appointments.empty?

    appointments.each_with_index do |appointment, i|
      actor = employees.sample
      role = appointment.role
      policy = appointment.policy
      PermissionLogs::WriteService.call(
        company: company,
        action: i.even? ? :granted : :revoked,
        actor: actor,
        role: role,
        policy: policy,
        appointment: appointment,
        from_workflow_status: i.even? ? "inactive" : "active",
        to_workflow_status: i.even? ? "active" : "inactive"
      )
    end

    first = appointments.first
    updater = employees.sample
    PermissionLogs::WriteService.call(
      company: company,
      action: :conditions_changed,
      actor: updater,
      role: first.role,
      policy: first.policy,
      appointment: first,
      tag_conditions_before: {},
      tag_conditions_after: { "brand" => "Apple" }
    )
  end

  def self.seed_table_config_logs(company, employees)
    company.table_configs.find_each do |config|
      actor = employees.sample
      TableConfigLog.create!(
        company: company, table_config: config,
        category: config.category, property_mapping: config.property_mapping,
        employee: actor, employee_name: actor&.name, action: :created,
        category_name: config.category&.name,
        property_mapping_name: config.property_mapping&.name,
        name: config.name, description: config.description,
        resource_name: config.resource_name, metadata: config.metadata,
        discarded_at: config.discarded_at,
        created_at: 6.days.ago, updated_at: 6.days.ago
      )
      updater = (employees - [ actor ]).sample || actor
      TableConfigLog.create!(
        company: company, table_config: config,
        category: config.category, property_mapping: config.property_mapping,
        employee: updater, employee_name: updater&.name, action: :updated,
        category_name: config.category&.name,
        property_mapping_name: config.property_mapping&.name,
        name: "#{config.name} (v2)", description: config.description,
        resource_name: config.resource_name, metadata: config.metadata,
        discarded_at: config.discarded_at,
        created_at: 2.days.ago, updated_at: 2.days.ago
      )
    end
  end
end
