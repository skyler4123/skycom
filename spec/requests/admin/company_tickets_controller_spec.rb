# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CompanyTicketsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let(:admin) { create(:user, :admin) }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Printer is down", priority: :urgent)
  end

  before do
    allow(WEBSOCKET).to receive(:publish_event)
    get sign_in_for_test_path(email: admin.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "access control" do
    it "redirects non-admin users" do
      get sign_in_for_test_path(email: company.user.email)

      get admin_company_tickets_path, as: :json

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET #index" do
    it "lists the cross-company pool with pagination and open count" do
      other_company = create(:company)
      other_employee = other_company.employees.find_by(business_type: "owner")
      CompanyTicket.create!(company: other_company, employee: other_employee, name: "Other co")

      get admin_company_tickets_path, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company_tickets"].size).to eq(2)
      expect(body).to have_key("pagination")
      expect(body["open_count"]).to eq(2)
    end

    it "filters unassigned tickets" do
      ticket.assign_to!(admin, actor: admin)

      get admin_company_tickets_path, params: { unassigned: "1" }, as: :json

      expect(JSON.parse(response.body)["company_tickets"]).to be_empty
    end
  end

  describe "GET #show" do
    it "returns the ticket with actor names on logs and forced-download attachments" do
      comment = CompanyTicketComment.create_for!(ticket: ticket,
        author: owner_employee, message: "with file")
      comment.file_attachments.attach(io: StringIO.new("%PDF"), filename: "a.pdf",
        content_type: "application/pdf")

      get admin_company_ticket_path(ticket), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["company_ticket"]
      expect(body["logs"].first["actor_name"]).to be_present
      expect(body["comments"].first["attachments"].first["url"]).to include("disposition=attachment")
    end
  end

  describe "POST #assign" do
    it "assigns the ticket to the current admin and publishes" do
      post assign_admin_company_ticket_path(ticket), as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.assigned_user).to eq(admin)
      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.channel_name(:company, company.id),
        event_key: :company_ticket_status_changed,
        data: hash_including(to_status: "assigned")
      )
    end

    it "rejects a second admin taking the ticket with 422" do
      ticket.assign_to!(admin, actor: admin)
      other_admin = create(:user, :admin)
      get sign_in_for_test_path(email: other_admin.email)

      post assign_admin_company_ticket_path(ticket), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "POST #comment" do
    it "stamps first_responded_at and publishes" do
      post comment_admin_company_ticket_path(ticket), params: {
        company_ticket_comment: { message: "On it" }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(ticket.reload.first_responded_at).to be_present
      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.channel_name(:company, company.id),
        event_key: :company_ticket_commented,
        data: hash_including(author_type: "User")
      )
    end
  end

  describe "POST #resolve / #reopen" do
    it "resolves (stamps resolved_at) and reopens (clears it)" do
      ticket.assign_to!(admin, actor: admin)

      post resolve_admin_company_ticket_path(ticket), as: :json
      expect(ticket.reload).to be_status_resolved
      expect(ticket.resolved_at).to be_present

      post reopen_admin_company_ticket_path(ticket), as: :json
      expect(ticket.reload).to be_status_open
      expect(ticket.resolved_at).to be_nil
    end
  end
end
