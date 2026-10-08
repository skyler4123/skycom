class Seed::CompanyTicketService
  CATEGORIES = %i[billing technical account feature_request other].freeze
  PRIORITIES = %i[low medium high urgent].freeze
  STATUSES = %i[open in_progress waiting_customer resolved closed].freeze

  def self.new(
    company:,
    employee:,
    name: "Support Ticket",
    description: nil,
    ticket_category: :other,
    priority: :medium,
    status: :open,
    rate: nil,
    assigned_user: nil,
    first_responded_at: nil,
    resolved_at: nil,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create ticket: No company or employee provided." if company.nil? || employee.nil?

    CompanyTicket.new(
      company: company,
      employee: employee,
      name: name,
      description: description,
      ticket_category: ticket_category,
      priority: priority,
      status: status,
      rate: rate,
      assigned_user: assigned_user,
      first_responded_at: first_responded_at,
      resolved_at: resolved_at,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    ticket = new(...)
    ticket.save!
    ticket
  end

  # Builds a coherent support thread through the production mutators
  # (assign_to! / transition_to! / create_for! / rate!) so seeded rows carry
  # the same logs and SLA stamps as live ones. Round-robin by index —
  # never random (docs/INIT_AND_ENRICH.md).
  def self.create_sample_thread(company:, employee:, staff:, index: 0)
    ticket = create(
      company: company,
      employee: employee,
      name: "Support Ticket #{index + 1}",
      description: "Seeded thread ##{index + 1} for the Help Center.",
      ticket_category: CATEGORIES[index % CATEGORIES.length],
      priority: PRIORITIES[index % PRIORITIES.length]
    )
    status = STATUSES[index % STATUSES.length]

    CompanyTicketComment.create_for!(
      ticket: ticket, author: employee, message: "Seeded request ##{index + 1} — please help."
    )

    case status
    when :open
      ticket
    when :in_progress, :waiting_customer
      ticket.assign_to!(staff, actor: staff)
      ticket.transition_to!(status, actor: staff, note: "Seeded triage.")
      CompanyTicketComment.create_for!(
        ticket: ticket, author: staff, message: "Seeded staff reply — looking into it."
      )
      ticket.reload
    when :resolved, :closed
      ticket.assign_to!(staff, actor: staff)
      CompanyTicketComment.create_for!(
        ticket: ticket, author: staff, message: "Seeded staff reply — fixed."
      )
      ticket.transition_to!(status, actor: staff, note: "Seeded resolution.")
      ticket.rate!((index % 5) + 1, employee: employee)
      ticket.reload
    end
  end
end
