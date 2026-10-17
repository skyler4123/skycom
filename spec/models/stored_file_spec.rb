# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoredFile, type: :model do
  let!(:company) { create(:company) }
  let!(:folder) { Folder.create!(company: company, name: "Bucket-A") }

  def pdf_attach(name = "doc.pdf")
    { io: Rails.root.join("faker/files/Untitled spreadsheet - Sheet1.pdf").open, filename: name, content_type: "application/pdf" }
  end

  def build_file(**attrs)
    StoredFile.new({ company: company, folder: folder, name: "contract.pdf" }.merge(attrs))
  end

  describe "success" do
    it "uploads a real faker pdf and syncs audit columns" do
      sf = build_file
      sf.file.attach(**pdf_attach)
      expect(sf.save).to be true
      sf.reload
      expect(sf.file).to be_attached
      expect(sf.file_size).to be > 0
      expect(sf.content_type).to eq("application/pdf")
      expect(sf.extension).to eq("pdf")
    end

    it "links to an invoice via attachable" do
      customer = create(:customer, company: company)
      order = create(:order, company: company, customer: customer)
      invoice = create(:invoice, order: order)
      sf = build_file(attachable: invoice)
      sf.file.attach(**pdf_attach)
      expect(sf.save).to be true
      expect(sf.reload.attachable).to eq(invoice)
    end
  end

  describe "failures" do
    it "rejects files at top level without folder" do
      sf = build_file(folder: nil)
      sf.file.attach(**pdf_attach)
      expect(sf).not_to be_valid
      expect(sf.errors[:folder].join).to match(/must exist|required|blank/i)
    end

    it "rejects cross-company folder" do
      other = create(:company)
      foreign_folder = Folder.create!(company: other, name: "Foreign")
      sf = build_file(folder: foreign_folder)
      sf.file.attach(**pdf_attach)
      expect(sf).not_to be_valid
    end

    it "rejects disallowed content type" do
      sf = build_file
      sf.file.attach(io: StringIO.new("#!/bin/sh"), filename: "run.sh", content_type: "application/x-sh")
      expect(sf).not_to be_valid
      expect(sf.errors.full_messages.join).to match(/type|allowed/i)
    end

    it "rejects oversize upload per CONSTANT" do
      sf = build_file
      big_limit = STORED_FILE_MAX_SIZES_BY_TYPE[:pdf]
      sf.file.attach(io: StringIO.new("a" * (big_limit + 1)), filename: "big.pdf", content_type: "application/pdf")
      expect(sf).not_to be_valid
      expect(sf.errors.full_messages.join).to match(/too big/i)
    end

    it "requires an attached file" do
      sf = build_file
      expect(sf).not_to be_valid
      expect(sf.errors[:file].join).to match(/attached|blank|required/i)
    end

    it "rejects cross-company attachable" do
      other = create(:company)
      other_customer = create(:customer, company: other)
      other_order = create(:order, company: other, customer: other_customer)
      foreign_invoice = create(:invoice, order: other_order)
      sf = build_file(attachable: foreign_invoice)
      sf.file.attach(**pdf_attach)
      expect(sf).not_to be_valid
      expect(sf.errors.full_messages.join).to match(/company/i)
    end

    it "rejects spoofed extension with allowed MIME" do
      sf = build_file
      sf.file.attach(io: StringIO.new("#!/bin/sh"), filename: "run.sh", content_type: "text/plain")
      expect(sf).not_to be_valid
    end
  end
end
