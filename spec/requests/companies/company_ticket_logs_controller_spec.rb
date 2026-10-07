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
  end

  describe "GET #show" do
    it "returns a single log row" do
      log = ticket.ticket_logs.first

      get company_company_ticket_log_path(company, log), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["company_ticket_log"]["action"]).to eq("created")
    end
  end
end
