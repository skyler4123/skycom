require "rails_helper"

RSpec.describe CompanyTicketComment do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company) }
  let(:admin_user) { create(:user, :admin) }
  let(:ticket) { CompanyTicket.create!(company: company, employee: employee, name: "VPN broken") }

  describe "validations" do
    it "requires message and a polymorphic author" do
      expect(CompanyTicketComment.new(company_ticket: ticket)).not_to be_valid
      expect(CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: "")).not_to be_valid
      expect(CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: "hello")).to be_valid
    end

    it "accepts a User author" do
      comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: admin_user, message: "looking into it")
      expect(comment).to be_valid
    end

    it "rejects an employee from another company" do
      other_employee = create(:employee, company: create(:company))
      comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: other_employee, message: "hi")
      expect(comment).not_to be_valid
    end

    it "rejects a ticket from another company" do
      other_company = create(:company)
      other_employee = create(:employee, company: other_company)
      other_ticket = CompanyTicket.create!(company: other_company,
        employee: other_employee, name: "x")
      comment = CompanyTicketComment.new(company: company, company_ticket: other_ticket,
        author: employee, message: "hi")
      expect(comment).not_to be_valid
    end
  end

  describe "author deletion" do
    it "blocks hard-deleting an employee author while comments exist" do
      CompanyTicketComment.create_for!(ticket: ticket, author: employee, message: "hi")

      expect(employee.destroy).to be(false)
      expect(CompanyTicketComment.count).to eq(1)
    end

    it "blocks hard-deleting a staff author while comments exist" do
      CompanyTicketComment.create_for!(ticket: ticket, author: admin_user, message: "hi")

      expect(admin_user.destroy).to be(false)
      expect(CompanyTicketComment.count).to eq(1)
    end
  end

  describe ".create_for!" do
    it "derives company from the ticket and logs the comment" do
      comment = CompanyTicketComment.create_for!(ticket: ticket, author: employee, message: "any update?")

      expect(comment.company).to eq(company)
      expect(ticket.ticket_logs.commented.count).to eq(1)
    end

    it "stamps first_responded_at on the first User comment only" do
      expect(ticket.first_responded_at).to be_nil

      CompanyTicketComment.create_for!(ticket: ticket, author: employee, message: "bump")
      expect(ticket.reload.first_responded_at).to be_nil

      CompanyTicketComment.create_for!(ticket: ticket, author: admin_user, message: "on it")
      first = ticket.reload.first_responded_at
      expect(first).to be_present

      CompanyTicketComment.create_for!(ticket: ticket, author: admin_user, message: "update")
      expect(ticket.reload.first_responded_at).to eq(first)
    end
  end

  describe "file attachments" do
    it "rejects executable content types" do
      comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: "see attached")
      comment.file_attachments.attach(
        io: StringIO.new("MZ fake binary"),
        filename: "run.exe",
        content_type: "application/x-msdownload"
      )
      expect(comment).not_to be_valid
    end

    it "rejects oversized files" do
      comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: "big file")
      comment.file_attachments.attach(
        io: StringIO.new("x" * (6 * 1024 * 1024)),
        filename: "big.pdf",
        content_type: "application/pdf"
      )
      expect(comment).not_to be_valid
    end

    it "accepts images, pdf, text and office docs" do
      comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: "docs")
      comment.file_attachments.attach(
        io: StringIO.new("fake png"),
        filename: "shot.png",
        content_type: "image/png"
      )
      expect(comment).to be_valid
    end

    it "leaves no orphan blobs when validation fails" do
      ticket # warm up lazy factories — their seed blobs must not pollute the count
      expect {
        comment = CompanyTicketComment.new(company: company, company_ticket: ticket,
          author: employee, message: "x")
        comment.file_attachments.attach(
          io: StringIO.new("MZ fake binary"),
          filename: "run.exe",
          content_type: "application/x-msdownload"
        )
        comment.save
      }.not_to change(ActiveStorage::Blob, :count)
    end
  end
end
