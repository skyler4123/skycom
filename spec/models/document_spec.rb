# spec/models/document_spec.rb
require "rails_helper"

RSpec.describe Document, type: :model do
  let!(:company) { create(:company) }
  let!(:document_group) { Seed::DocumentGroupService.create(company: company) }

  def build_doc(**attrs)
    Seed::DocumentService.new(
      company: company,
      document_group: document_group,
      title: "How to do something",
      **attrs
    )
  end

  def png_blob(i = 0)
    { io: StringIO.new("pngdata#{i}"), filename: "img#{i}.png", content_type: "image/png" }
  end

  def pdf_blob(i = 0)
    { io: StringIO.new("pdfdata#{i}"), filename: "file#{i}.pdf", content_type: "application/pdf" }
  end

  describe "validations" do
    it "requires a title" do
      doc = build_doc
      doc.title = nil
      expect(doc).not_to be_valid
    end

    it "allows blank body_markdown" do
      expect(build_doc(body_markdown: nil)).to be_valid
    end

    it "accepts markdown body within limit" do
      expect(build_doc(body_markdown: "# Hello\n\nSome **bold** text")).to be_valid
    end

    it "rejects body_markdown over 100000 characters" do
      expect(build_doc(body_markdown: "a" * 100_001)).not_to be_valid
    end
  end

  describe "image attachments" do
    it "accepts up to 10 images" do
      doc = build_doc
      10.times { |i| doc.image_attachments.attach(**png_blob(i)) }
      expect(doc).to be_valid
    end

    it "rejects an 11th image" do
      doc = build_doc
      11.times { |i| doc.image_attachments.attach(**png_blob(i)) }
      expect(doc).not_to be_valid
    end

    it "rejects oversize images" do
      doc = build_doc
      doc.image_attachments.attach(
        io: StringIO.new("a" * (1.megabyte + 1)),
        filename: "big.png",
        content_type: "image/png"
      )
      expect(doc).not_to be_valid
    end

    it "rejects non-image types in the image slot" do
      doc = build_doc
      doc.image_attachments.attach(
        io: StringIO.new("not an image"), filename: "evil.txt", content_type: "text/plain"
      )
      expect(doc).not_to be_valid
    end
  end

  describe "file attachments" do
    it "accepts up to 5 files" do
      doc = build_doc
      5.times { |i| doc.file_attachments.attach(**pdf_blob(i)) }
      expect(doc).to be_valid
    end

    it "rejects a 6th file" do
      doc = build_doc
      6.times { |i| doc.file_attachments.attach(**pdf_blob(i)) }
      expect(doc).not_to be_valid
    end

    it "rejects oversize files" do
      doc = build_doc
      doc.file_attachments.attach(
        io: StringIO.new("a" * (5.megabytes + 1)),
        filename: "big.pdf",
        content_type: "application/pdf"
      )
      expect(doc).not_to be_valid
    end

    it "rejects disallowed file types" do
      doc = build_doc
      doc.file_attachments.attach(
        io: StringIO.new("#!/bin/sh"), filename: "run.sh", content_type: "application/x-sh"
      )
      expect(doc).not_to be_valid
    end

    it "allows images and files together" do
      doc = build_doc
      doc.image_attachments.attach(**png_blob(0))
      doc.file_attachments.attach(**pdf_blob(0))
      expect(doc).to be_valid
    end
  end
end
