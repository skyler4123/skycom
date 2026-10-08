require "rails_helper"

RSpec.describe "company ticket seeding" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }
  let(:employee) { create(:employee, company: company) }
  let(:staff) { Seed::UserService.create(system_role: :admin) }

  it "builds tickets and comments through the builders" do
    ticket = Seed::CompanyTicketService.create(company: company, employee: employee,
      name: "Seeded issue", ticket_category: :billing, priority: :high)
    expect(ticket).to be_persisted

    comment = Seed::CompanyTicketCommentService.create(company: company,
      company_ticket: ticket, author: employee, message: "seeded comment")
    expect(comment).to be_persisted
  end

  it "grants managers full ticket permissions and requesters create/read" do
    manager = Role.find_by!(name: "Manager", company: company)
    %w[CompanyTicket CompanyTicketComment CompanyTicketLog].each do |resource|
      %w[create read update delete].each do |action|
        policy = Policy.find_by!(company: company, resource: resource, action: action)
        appointment = PolicyRoleAppointment.find_by!(company: company, policy: policy, role: manager)
        expect(appointment.workflow_status).to eq("active"), "expected Manager #{action} #{resource} active"
      end
    end

    cashier = Role.find_by!(name: "Cashier", company: company)
    create_policy = Policy.find_by!(company: company, resource: "CompanyTicket", action: "create")
    expect(PolicyRoleAppointment.find_by!(company: company, policy: create_policy, role: cashier).workflow_status).to eq("active")
    delete_policy = Policy.find_by!(company: company, resource: "CompanyTicket", action: "delete")
    expect(PolicyRoleAppointment.find_by!(company: company, policy: delete_policy, role: cashier).workflow_status).not_to eq("active")
    log_read = Policy.find_by!(company: company, resource: "CompanyTicketLog", action: "read")
    expect(PolicyRoleAppointment.find_by!(company: company, policy: log_read, role: cashier).workflow_status).to eq("active")
  end

  it "keeps SLA stamps coherent on a seeded thread" do
    ticket = Seed::CompanyTicketService.create_sample_thread(
      company: company, employee: employee, staff: staff, index: 3)

    expect(ticket).to be_status_resolved
    expect(ticket.first_responded_at).to be_present
    expect(ticket.resolved_at).to be_present
    expect(ticket.rate).to be_between(1, 5)
    expect(ticket.ticket_comments.count).to be >= 2
  end

  it "leaves open threads without response stamps" do
    ticket = Seed::CompanyTicketService.create_sample_thread(
      company: company, employee: employee, staff: staff, index: 0)

    expect(ticket).to be_status_open
    expect(ticket.first_responded_at).to be_nil
    expect(ticket.resolved_at).to be_nil
  end
end
