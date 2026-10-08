require "rails_helper"

RSpec.describe CompanyTicket do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:admin_user) { create(:user, :admin) }

  def build_ticket(attrs = {})
    CompanyTicket.new({ company: company, employee: employee, name: "Printer is down" }.merge(attrs))
  end

  describe "validations" do
    it "requires name, company and employee" do
      expect(CompanyTicket.new).not_to be_valid
      expect(build_ticket(name: "")).not_to be_valid
      expect(build_ticket).to be_valid
    end

    it "defaults status to open and priority to medium" do
      ticket = build_ticket
      expect(ticket.status).to eq("open")
      expect(ticket.priority).to eq("medium")
    end

    it "rejects rate 0 and 6, allows nil and 3 on resolved tickets" do
      expect(build_ticket(rate: 0, status: :resolved)).not_to be_valid
      expect(build_ticket(rate: 6, status: :resolved)).not_to be_valid
      expect(build_ticket(rate: nil)).to be_valid
      expect(build_ticket(rate: 3, status: :resolved)).to be_valid
    end

    it "rejects rate on unresolved tickets" do
      expect(build_ticket(rate: 5, status: :open)).not_to be_valid
      expect(build_ticket(rate: 5, status: :in_progress)).not_to be_valid
    end
  end

  describe "#transition_to!" do
    it "stamps resolved_at when transitioning to resolved" do
      ticket = build_ticket
      ticket.save!
      expect(ticket.resolved_at).to be_nil

      ticket.transition_to!(:resolved, actor: admin_user)

      expect(ticket.reload).to be_status_resolved
      expect(ticket.resolved_at).to be_present
    end

    it "clears resolved_at on reopen to open" do
      ticket = build_ticket(status: :resolved, resolved_at: 1.day.ago)
      ticket.save!(validate: false)

      ticket.transition_to!(:open, actor: admin_user)

      expect(ticket.reload).to be_status_open
      expect(ticket.resolved_at).to be_nil
    end

    it "writes a status_changed log with from/to" do
      ticket = build_ticket
      ticket.save!

      expect {
        ticket.transition_to!(:in_progress, actor: admin_user)
      }.to change { ticket.ticket_logs.status_changed.count }.by(1)

      log = ticket.ticket_logs.status_changed.last
      expect(log.from_status).to eq("open")
      expect(log.to_status).to eq("in_progress")
    end
  end

  describe "#assign_to!" do
    it "assigns an unassigned ticket to a User and logs it" do
      ticket = build_ticket
      ticket.save!

      ticket.assign_to!(admin_user, actor: admin_user)

      expect(ticket.reload.assigned_user).to eq(admin_user)
      expect(ticket.ticket_logs.assigned.count).to eq(1)
    end

    it "is idempotent when assigning the same user twice" do
      ticket = build_ticket
      ticket.save!
      ticket.assign_to!(admin_user, actor: admin_user)

      expect {
        ticket.assign_to!(admin_user, actor: admin_user)
      }.not_to(change { ticket.ticket_logs.assigned.count })
    end

    it "raises when a different user tries to take an assigned ticket" do
      ticket = build_ticket
      ticket.save!
      ticket.assign_to!(admin_user, actor: admin_user)
      other = create(:user, :admin)

      expect {
        ticket.assign_to!(other, actor: other)
      }.to raise_error(CompanyTicket::AlreadyAssigned)
    end
  end

  describe "#rate!" do
    it "records a 1..5 rating on a resolved ticket by its creator" do
      ticket = build_ticket(status: :resolved)
      ticket.save!(validate: false)

      ticket.rate!(5, employee: employee)

      expect(ticket.reload.rate).to eq(5)
      expect(ticket.ticket_logs.rated.count).to eq(1)
    end

    it "rejects rating by a different employee" do
      ticket = build_ticket(status: :resolved)
      ticket.save!(validate: false)
      other = create(:employee, company: company)

      expect {
        ticket.rate!(5, employee: other)
      }.to raise_error(CompanyTicket::NotTicketOwner)
    end

    it "rejects rating an unresolved ticket" do
      ticket = build_ticket
      ticket.save!

      expect {
        ticket.rate!(5, employee: employee)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".open_count_key / .admin_open_count_key" do
    it "builds deterministic sync-cache keys" do
      expect(CompanyTicket.open_count_key(company.id)).to eq("company_tickets/#{company.id}/open_count")
      expect(CompanyTicket.admin_open_count_key).to eq("company_tickets/admin/open_count")
    end
  end

  describe "creator deletion" do
    it "blocks hard-deleting the creator while tickets exist" do
      ticket = build_ticket
      ticket.save!

      expect(employee.destroy).to be(false)
      expect(CompanyTicket.exists?(ticket.id)).to be(true)
    end
  end
end
