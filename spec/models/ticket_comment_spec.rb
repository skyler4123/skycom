require "rails_helper"

RSpec.describe TicketComment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:ticket) }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
  end

  it "records a TicketLog on create" do
    company = create(:company)
    employee = create(:employee, company: company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "tickets")
    ticket = create(:ticket, company: company, category: category, name: "Fix printer", employee: employee, created_by_employee: employee)
    before_count = ticket.ticket_logs.count
    TicketComment.create_for!(ticket: ticket, employee: employee, message: "Working on it")
    expect(ticket.ticket_logs.count).to eq(before_count + 1)
  end
end