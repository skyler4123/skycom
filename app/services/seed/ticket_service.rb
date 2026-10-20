class Seed::TicketService
  def self.new(
    company:,
    employee: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    priority: :medium,
    lifecycle_status: :active,
    workflow_status: nil,
    workflow_step: nil,
    assigned_employee: nil,
    created_by_employee: nil,
    skip_workflow: false,
    discarded_at: nil
  )
    raise "Cannot create ticket: No company provided." if company.nil?

    Ticket.new(
      company: company,
      employee: employee || company.employees.first,
      category: category,
      property_mapping: property_mapping,
      name: name || "Ticket #{Faker::Lorem.words(number: 2).join(' ').titleize}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      priority: priority,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      workflow_step: workflow_step,
      assigned_employee: assigned_employee,
      created_by_employee: created_by_employee || employee,
      skip_workflow: skip_workflow,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    ticket = new(...)
    if ticket.category.nil? && ticket.company.present?
      ticket.category = Seed::CategoryService.random_for(
        company: ticket.company,
        resource_name: "tickets"
      ) rescue Seed::CategoryService.find_or_create_for(company: ticket.company, resource_name: "tickets")
    end
    if ticket.property_mapping.nil? && ticket.category.present?
      ticket.property_mapping = ticket.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(ticket) rescue nil
    ticket.save!
    ticket
  end

  def self.find_or_create_for(company:, resource_name: "tickets")
    Seed::CategoryService.find_or_create_for(company: company, resource_name: resource_name)
  end
end