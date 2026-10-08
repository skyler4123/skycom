class Seed::CompanyTicketCommentService
  def self.new(
    company:,
    company_ticket:,
    author:,
    message: "Seeded comment"
  )
    raise "Cannot create comment: No ticket or author provided." if company_ticket.nil? || author.nil?

    CompanyTicketComment.new(
      company: company,
      company_ticket: company_ticket,
      author: author,
      message: message
    )
  end

  def self.create(...)
    comment = new(...)
    comment.save!
    comment
  end
end
