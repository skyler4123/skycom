class Seed::TicketCommentService
  def self.create(company:, ticket:, employee: nil, message: nil)
    employee ||= ticket.employee
    TicketComment.create_for!(
      ticket: ticket,
      employee: employee,
      message: message || Faker::Lorem.sentence(word_count: 8)
    )
  end
end