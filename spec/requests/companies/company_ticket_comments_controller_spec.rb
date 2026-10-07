# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::CompanyTicketCommentsController", type: :request do
  let(:company) { create(:company) }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:ticket) do
    CompanyTicket.create!(company: company, employee: owner_employee, name: "VPN broken")
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

  describe "POST #create" do
    it "creates an employee comment and publishes an event" do
      expect {
        post company_company_ticket_comments_path(company), params: {
          company_ticket_comment: { company_ticket_id: ticket.id, message: "any update?" }
        }, as: :json
      }.to change(CompanyTicketComment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(WEBSOCKET).to have_received(:publish_event).with(
        channel: WEBSOCKET.channel_name(:company, company.id),
        event_key: :company_ticket_commented,
        data: hash_including(comment: hash_including("message" => "any update?", "author_type" => "Employee", "attachments" => []))
      )
      body = JSON.parse(response.body)["company_ticket_comment"]
      expect(body["message"]).to eq("any update?")
      expect(body["author_type"]).to eq("Employee")
      expect(body).to have_key("author_name")
      expect(body).to have_key("created_at")
      expect(body["attachments"]).to eq([])
    end

    it "rejects blank messages with 422 errors" do
      post company_company_ticket_comments_path(company), params: {
        company_ticket_comment: { company_ticket_id: ticket.id, message: "" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "returns 404 for a foreign ticket" do
      other_company = create(:company)
      other_employee = other_company.employees.find_by(business_type: "owner")
      foreign = CompanyTicket.create!(company: other_company, employee: other_employee, name: "F")

      post company_company_ticket_comments_path(company), params: {
        company_ticket_comment: { company_ticket_id: foreign.id, message: "hi" }
      }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
