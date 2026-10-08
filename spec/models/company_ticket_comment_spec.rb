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

  describe "attachments" do
    def build_comment(message: "see attached")
      CompanyTicketComment.new(company: company, company_ticket: ticket,
        author: employee, message: message)
    end

    it "is valid with no attachments" do
      expect(build_comment).to be_valid
    end

    it "accepts a png image up to 2MB" do
      comment = build_comment
      comment.image_attachment.attach(
        io: StringIO.new("fake png"),
        filename: "shot.png",
        content_type: "image/png"
      )
      expect(comment).to be_valid
    end

    it "accepts a jpeg image" do
      comment = build_comment
      comment.image_attachment.attach(
        io: StringIO.new("fake jpeg"),
        filename: "shot.jpg",
        content_type: "image/jpeg"
      )
      expect(comment).to be_valid
    end

    it "rejects non-png/jpeg images" do
      comment = build_comment
      comment.image_attachment.attach(
        io: StringIO.new("fake gif"),
        filename: "anim.gif",
        content_type: "image/gif"
      )
      expect(comment).not_to be_valid
    end

    it "rejects images over 2MB" do
      comment = build_comment(message: "huge shot")
      comment.image_attachment.attach(
        io: StringIO.new("x" * (2.megabytes + 1)),
        filename: "huge.png",
        content_type: "image/png"
      )
      expect(comment).not_to be_valid
    end

    it "accepts an excel file up to 1MB" do
      comment = build_comment
      comment.file_attachment.attach(
        io: StringIO.new("x" * 1.megabyte),
        filename: "report.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      expect(comment).to be_valid
    end

    it "rejects non-excel files" do
      comment = build_comment
      comment.file_attachment.attach(
        io: StringIO.new("%PDF"),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      expect(comment).not_to be_valid
    end

    it "rejects excel files over 1MB" do
      comment = build_comment(message: "heavy sheet")
      comment.file_attachment.attach(
        io: StringIO.new("x" * (1.megabyte + 1)),
        filename: "heavy.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      expect(comment).not_to be_valid
    end

    it "rejects executable content types" do
      comment = build_comment
      comment.file_attachment.attach(
        io: StringIO.new("MZ fake binary"),
        filename: "run.exe",
        content_type: "application/x-msdownload"
      )
      expect(comment).not_to be_valid
    end

    it "rejects having both an image and a file" do
      comment = build_comment(message: "both")
      comment.image_attachment.attach(
        io: StringIO.new("fake png"), filename: "shot.png", content_type: "image/png"
      )
      comment.file_attachment.attach(
        io: StringIO.new("x"), filename: "r.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:base].join).to match(/either.*or/i)
    end

    it "routes create_for! files by content type" do
      image = CompanyTicketComment.create_for!(
        ticket: ticket, author: employee, message: "shot",
        files: [ { io: StringIO.new("fake png"), filename: "shot.png", content_type: "image/png" } ]
      )
      expect(image.image_attachment).to be_attached
      expect(image.file_attachment).not_to be_attached

      sheet = CompanyTicketComment.create_for!(
        ticket: ticket, author: employee, message: "sheet",
        files: [ { io: StringIO.new("x"), filename: "r.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" } ]
      )
      expect(sheet.file_attachment).to be_attached
      expect(sheet.image_attachment).not_to be_attached
    end

    it "serves a display variant capped at 800px for large images" do
      path = Rails.root.join("faker/images/randoms/567-500x1000.jpg")
      comment = CompanyTicketComment.create_for!(
        ticket: ticket, author: employee, message: "big screenshot",
        files: [ File.open(path) ]
      )

      variant = comment.image_attachment.variant(:display).processed
      image = MiniMagick::Image.open(ActiveStorage::Blob.service.path_for(variant.key))
      expect(image.width).to be <= 800
      expect(image.height).to be <= 800
    end

    it "leaves no orphan blobs when validation fails" do
      ticket # warm up lazy factories — their seed blobs must not pollute the count
      expect {
        comment = build_comment(message: "x")
        comment.file_attachment.attach(
          io: StringIO.new("MZ fake binary"),
          filename: "run.exe",
          content_type: "application/x-msdownload"
        )
        comment.save
      }.not_to change(ActiveStorage::Blob, :count)
    end
  end
end
