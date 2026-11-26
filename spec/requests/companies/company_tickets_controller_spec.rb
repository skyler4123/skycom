# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CompanyTicketsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee,
      name: "Printer is down", description: "3rd floor", ticket_category: :technical)
  end

  before do
    allow(WEBSOCKET).to receive(:publish_event)
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def sign_in_as(employee)
    get sign_in_for_test_path(email: employee.user.email)
  end

  describe "GET #index" do
    it "returns the company's tickets with pagination and open count" do
      get company_company_tickets_path(company), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["company_tickets"].size).to eq(1)
      expect(body["company_tickets"].first["name"]).to eq("Printer is down")
      expect(body).to have_key("pagination")
      expect(body["open_count"]).to eq(1)
    end

    it "filters by status and priority" do
      ticket.transition_to!(:resolved, actor: owner_employee)

      get company_company_tickets_path(company), params: { status: "resolved" }, as: :json
      expect(JSON.parse(response.body)["company_tickets"].size).to eq(1)

      get company_company_tickets_path(company), params: { status: "open" }, as: :json
      expect(JSON.parse(response.body)["company_tickets"].size).to eq(0)

      get company_company_tickets_path(company), params: { priority: "urgent" }, as: :json
      expect(JSON.parse(response.body)["company_tickets"].size).to eq(0)
    end

    it "rejects unknown enum filters with 422" do
      get company_company_tickets_path(company), params: { status: "bogus" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "scopes to the current company" do
      other_company = create(:company)
      other_employee = other_company.employees.find_by(business_type: "owner")
      CompanyTicket.create!(company: other_company, employee: other_employee, name: "Foreign")

      get company_company_tickets_path(company), as: :json

      names = JSON.parse(response.body)["company_tickets"].map { |t| t["name"] }
      expect(names).not_to include("Foreign")
    end

    it "forbids another company's scope" do
      other_company = create(:company)

      get company_company_tickets_path(other_company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "denies employees without grants" do
      plain = create(:employee, company: company)
      get sign_in_for_test_path(email: plain.user.email)

      get company_company_tickets_path(company), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "filters to only the current employee tickets with mine=1" do
      other = create(:employee, company: company)
      CompanyTicket.create!(company: company, employee: other,
        name: "Other printer", ticket_category: :technical)

      get company_company_tickets_path(company), params: { mine: "1" }, as: :json

      expect(response).to have_http_status(:ok)
      names = JSON.parse(response.body)["company_tickets"].map { |t| t["name"] }
      expect(names).to include("Printer is down")
      expect(names).not_to include("Other printer")
    end

    it "returns all tickets for the owner without mine param" do
      other = create(:employee, company: company)
      CompanyTicket.create!(company: company, employee: other,
        name: "Other printer", ticket_category: :technical)

      get company_company_tickets_path(company), as: :json

      names = JSON.parse(response.body)["company_tickets"].map { |t| t["name"] }
      expect(names).to include("Printer is down", "Other printer")
    end

    it "shows company-wide tickets plus the reader's own private tickets" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
      other = create(:employee, company: company)
      CompanyTicket.create!(company: company, employee: reader, name: "Reader private")
      CompanyTicket.create!(company: company, employee: other, name: "Shared",
        visibility: :company_wide)
      CompanyTicket.create!(company: company, employee: other, name: "Hidden")

      sign_in_as(reader)
      get company_company_tickets_path(company), as: :json

      body = JSON.parse(response.body)
      names = body["company_tickets"].map { |t| t["name"] }
      expect(names).to include("Reader private", "Shared")
      expect(names).not_to include("Hidden", "Printer is down")
      expect(body["open_count"]).to eq(2)
      expect(body["company_tickets"].map { |t| t["visibility"] }).to include("only_me", "company_wide")
    end
  end

  describe "GET #show" do
    it "returns the ticket with comments, logs and attachment flags" do
      comment = CompanyTicketComment.create_for!(ticket: ticket,
        author: owner_employee, message: "looking")
      comment.image_attachment.attach(io: StringIO.new("fake png"), filename: "shot.png",
        content_type: "image/png")

      get company_company_ticket_path(company, ticket), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["company_ticket"]
      expect(body["name"]).to eq("Printer is down")
      expect(body["comments"].size).to eq(1)
      expect(body["comments"].first["attachments"].first["image"]).to be(true)
      expect(body["logs"].map { |l| l["action"] }).to include("created", "commented")
    end

    it "renders excel attachments with image false" do
      comment = CompanyTicketComment.create_for!(ticket: ticket,
        author: owner_employee, message: "doc")
      comment.file_attachment.attach(io: StringIO.new("fake-xlsx"), filename: "a.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")

      get company_company_ticket_path(company, ticket), as: :json

      attachments = JSON.parse(response.body)["company_ticket"]["comments"].first["attachments"]
      expect(attachments.first["image"]).to be(false)
      expect(attachments.first["content_type"]).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(attachments.first["url"]).to include("disposition=attachment")
    end

    it "returns 404 for a foreign ticket" do
      other_company = create(:company)
      other_employee = other_company.employees.find_by(business_type: "owner")
      foreign = CompanyTicket.create!(company: other_company, employee: other_employee, name: "F")

      get company_company_ticket_path(company, foreign), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another employee's private ticket" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
      other = create(:employee, company: company)
      hidden = CompanyTicket.create!(company: company, employee: other, name: "Hidden")

      sign_in_as(reader)
      get company_company_ticket_path(company, hidden), as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "allows a reader to open a company-wide ticket and exposes manageability" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :read)
      other = create(:employee, company: company)
      shared = CompanyTicket.create!(company: company, employee: other, name: "Shared",
        visibility: :company_wide)

      sign_in_as(reader)
      get company_company_ticket_path(company, shared), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["company_ticket"]
      expect(body["visibility"]).to eq("company_wide")
      expect(body["can_manage_visibility"]).to be(false)
    end
  end

  describe "POST #create" do
    it "creates a ticket owned by the current employee and publishes an event" do
      expect {
        post company_company_tickets_path(company), params: {
          company_ticket: { name: "WiFi down", description: "lobby",
            ticket_category: "technical", priority: "urgent" }
        }, as: :json
      }.to change(CompanyTicket, :count).by(1)

      expect(response).to have_http_status(:created)
      created = CompanyTicket.last
      expect(created.employee).to eq(owner_employee)
      expect(created).to be_status_open
      expect(created).to be_only_me
      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.channel_name(:company, company.id),
        event_key: :company_ticket_created,
        data: { id: created.id }
      )
    end

    it "accepts an explicit company-wide visibility" do
      post company_company_tickets_path(company), params: {
        company_ticket: { name: "Shared request", ticket_category: "technical",
          visibility: "company_wide" }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(CompanyTicket.last).to be_company_wide
    end

    it "rejects an unknown visibility with 422 and creates nothing" do
      expect {
        post company_company_tickets_path(company), params: {
          company_ticket: { name: "Bogus", ticket_category: "technical",
            visibility: "branch" }
        }, as: :json
      }.not_to change(CompanyTicket, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "rejects blank name with 422 errors" do
      post company_company_tickets_path(company), params: {
        company_ticket: { name: "", ticket_category: "billing" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "never permits status assignment" do
      post company_company_tickets_path(company), params: {
        company_ticket: { name: "Sneaky", ticket_category: "other", status: "resolved" }
      }, as: :json

      expect(CompanyTicket.last).to be_status_open
    end
  end

  describe "PATCH #update" do
    it "lets the creator share a private ticket and logs the change" do
      patch company_company_ticket_path(company, ticket), params: {
        company_ticket: { visibility: "company_wide" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload).to be_company_wide
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Visibility updated")
      expect(body["company_ticket"]["visibility"]).to eq("company_wide")
      expect(body["company_ticket"]["can_manage_visibility"]).to be(true)

      log = ticket.ticket_logs.visibility_changed.last
      expect(log.from_status).to eq("only_me")
      expect(log.to_status).to eq("company_wide")
    end

    it "rejects a non-creator with 403 and keeps the visibility" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :update)
      shared = CompanyTicket.create!(company: company, employee: owner_employee,
        name: "Owner shared", visibility: :company_wide)

      sign_in_as(reader)
      patch company_company_ticket_path(company, shared), params: {
        company_ticket: { visibility: "only_me" }
      }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(shared.reload).to be_company_wide
    end

    it "rejects the company owner when they are not the creator" do
      other = create(:employee, company: company)
      other_private = CompanyTicket.create!(company: company, employee: other,
        name: "Other private")

      patch company_company_ticket_path(company, other_private), params: {
        company_ticket: { visibility: "company_wide" }
      }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(other_private.reload).to be_only_me
    end

    it "returns 404 for a private ticket the reader cannot see" do
      reader = grant_company_ticket_permissions(create(:employee, company: company), :update)
      other = create(:employee, company: company)
      hidden = CompanyTicket.create!(company: company, employee: other, name: "Hidden")

      sign_in_as(reader)
      patch company_company_ticket_path(company, hidden), params: {
        company_ticket: { visibility: "company_wide" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(hidden.reload).to be_only_me
    end

    it "rejects an unknown visibility with 422" do
      patch company_company_ticket_path(company, ticket), params: {
        company_ticket: { visibility: "branch" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
      expect(ticket.reload).to be_only_me
    end
  end

  describe "POST #rate" do
    it "records the creator rating on a resolved ticket and publishes" do
      ticket.transition_to!(:resolved, actor: owner_employee)

      post rate_company_company_ticket_path(company, ticket), params: {
        company_ticket: { rate: 5 }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.rate).to eq(5)
      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.channel_name(:company, company.id),
        event_key: :company_ticket_status_changed,
        data: { id: ticket.id }
      )
    end

    it "rejects rating by a non-creator with 403" do
      ticket.transition_to!(:resolved, actor: owner_employee)
      other = create(:employee, company: company)
      get sign_in_for_test_path(email: other.user.email)

      post rate_company_company_ticket_path(company, ticket), params: {
        company_ticket: { rate: 5 }
      }, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects rating an unresolved ticket with 422" do
      post rate_company_company_ticket_path(company, ticket), params: {
        company_ticket: { rate: 5 }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
