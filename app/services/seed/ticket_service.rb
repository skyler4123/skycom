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

  # Builds a coherent internal ticket thread through the production mutators
  # (Workflows::AdvanceService / TicketComment) so seeded rows carry the same
  # logs and workflow stamps as live ones. Round-robin by index — never random.
  def self.create_sample_thread(company:, employee:, staff: nil, index: 0)
    categories = Category.where(company: company, resource_name: "tickets").order(:id).to_a
    return if categories.empty?

    staff_employee = staff.is_a?(Employee) ? staff : company.employees.where.not(business_type: :owner).first

    ticket = create(
      company: company,
      employee: employee,
      category: categories[index % categories.length],
      priority: %i[low medium high urgent][index % 4],
      name: "Internal Ticket #{index + 1}",
      description: "Seeded internal ticket ##{index + 1}.",
      created_by_employee: employee
    )

    Seed::TicketCommentService.create(company: company, ticket: ticket, employee: employee,
      message: "Seeded request ##{index + 1} — please handle.")

    if staff_employee.present?
      ticket.update!(assigned_employee: staff_employee) rescue nil

      case index % 4
      when 0 # completed end-to-end
        4.times { Workflows::AdvanceService.call(subject: ticket, employee: employee, outcome: "approved") }
        Seed::TicketCommentService.create(company: company, ticket: ticket, employee: staff_employee,
          message: "Seeded reply — resolved.")
      when 1 # rejected
        Workflows::AdvanceService.call(subject: ticket, employee: employee, outcome: "rejected", note: "Not feasible.")
        Seed::TicketCommentService.create(company: company, ticket: ticket, employee: staff_employee,
          message: "Seeded reply — rejected.")
      when 2 # reworked then completed
        step_one = ticket.workflow_step&.workflow&.workflow_steps&.find_by(position: 1)
        Workflows::AdvanceService.call(subject: ticket, employee: employee, outcome: "rework",
          note: "Rework needed.", target_step: step_one) if step_one
        4.times { Workflows::AdvanceService.call(subject: ticket, employee: employee, outcome: "approved") }
        Seed::TicketCommentService.create(company: company, ticket: ticket, employee: staff_employee,
          message: "Seeded reply — reworked and done.")
      when 3 # left pending (To Do)
        Seed::TicketCommentService.create(company: company, ticket: ticket, employee: staff_employee,
          message: "Seeded reply — triage.")
      end
    end

    ticket.reload
  rescue StandardError => e
    Rails.logger.warn("Ticket sample thread failed for #{company.id}: #{e.class}: #{e.message}")
    ticket
  end
end
