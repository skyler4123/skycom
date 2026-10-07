require "rails_helper"

RSpec.describe CompanyTicketLog do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:admin_user) { create(:user, :admin) }
  let(:ticket) { CompanyTicket.create!(company: company, employee: employee, name: "Login fails") }

  it "records created/assigned/status_changed/commented/rated with actor and ticket" do
    created = CompanyTicketLog.record!(ticket: ticket, action: :created, actor: employee)
    expect(created).to be_persisted
    expect(created.company).to eq(company)

    log = CompanyTicketLog.record!(ticket: ticket, action: :status_changed,
      actor: admin_user, from_status: "open", to_status: "in_progress", note: "picked up")
    expect(log.from_status).to eq("open")
    expect(log.to_status).to eq("in_progress")
    expect(log.note).to eq("picked up")
  end

  it "allows system transitions without an actor" do
    log = CompanyTicketLog.record!(ticket: ticket, action: :created)
    expect(log.actor).to be_nil
  end

  it "requires action" do
    expect(CompanyTicketLog.new(company: company, company_ticket: ticket)).not_to be_valid
  end
end
