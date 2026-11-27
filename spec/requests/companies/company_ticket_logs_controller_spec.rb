# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CompanyTicketLogsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee, name: "Login fails")
  end

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns the ticket audit trail" do
      ticket.transition_to!(:in_progress, actor: owner_employee)

      get company_company_ticket_logs_path(company), params: { company_ticket_id: ticket.id }, as: :json

      expect(response).to have_http_status(:ok)
      actions = JSON.parse(response.body)["company_ticket_logs"].map { |l| l["action"] }
      expect(actions).to include("created", "status_changed")
    end

    it "hides another employee's private ticket trail from a reader" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :read,
        resource: "CompanyTicketLog")
      other = create(:employee, company: company)
      hidden = CompanyTicket.create!(company: company, employee: other, name: "Hidden")
      hidden.transition_to!(:in_progress, actor: other, note: "hidden secret")
      shared = CompanyTicket.create!(company: company, employee: other, name: "Shared",
        visibility: :company_wide)
      shared.transition_to!(:in_progress, actor: other, note: "shared note")

      get sign_in_for_test_path(email: reader.user.email)
      get company_company_ticket_logs_path(company), as: :json

      notes = JSON.parse(response.body)["company_ticket_logs"].map { |l| l["note"] }
      expect(notes).to include("shared note")
      expect(notes).not_to include("hidden secret")
    end
  end

  describe "GET #show" do
    it "returns a single log row" do
      log = ticket.ticket_logs.first

      get company_company_ticket_log_path(company, log), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["company_ticket_log"]["action"]).to eq("created")
    end

    it "returns 404 for a hidden ticket's log" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :read,
        resource: "CompanyTicketLog")
      other = create(:employee, company: company)
      hidden = CompanyTicket.create!(company: company, employee: other, name: "Hidden")
      hidden_log = hidden.ticket_logs.first

      get sign_in_for_test_path(email: reader.user.email)
      get company_company_ticket_log_path(company, hidden_log), as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
