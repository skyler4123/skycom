# frozen_string_literal: true

require "rails_helper"

RSpec.describe Folder, type: :model do
  let!(:company) { create(:company) }

  def build_folder(**attrs)
    Folder.new({ company: company, name: "Bucket-A" }.merge(attrs))
  end

  describe "validations" do
    it "requires a name" do
      f = build_folder(name: nil)
      expect(f).not_to be_valid
    end
    it "rejects duplicate name under same parent" do
      build_folder.save!
      dup = build_folder
      expect(dup).not_to be_valid
    end

    it "allows same name under different parent" do
      parent_a = build_folder(name: "Parent-A")
      parent_a.save!
      parent_b = build_folder(name: "Parent-B")
      parent_b.save!
      build_folder(name: "Child", parent: parent_a).save!
      other = build_folder(name: "Child", parent: parent_b)
      expect(other).to be_valid
    end

    it "rejects cross-company parent" do
      other_company = create(:company)
      foreign_parent = Folder.create!(company: other_company, name: "Foreign")
      f = build_folder(parent: foreign_parent)
      expect(f).not_to be_valid
      expect(f.errors.full_messages.join).to match(/company/i)
    end

    it "rejects parent that is a descendant (cycle)" do
      parent = build_folder(name: "Parent")
      parent.save!
      child = build_folder(name: "Child", parent: parent)
      child.save!
      parent.parent = child
      expect(parent).not_to be_valid
      expect(parent.errors[:parent].join).to match(/cycle|descendant/i)
    end
  end

  describe "destroy guard" do
    it "blocks destroy when children exist" do
      parent = build_folder
      parent.save!
      build_folder(name: "Child", parent: parent).save!
      expect(parent.destroy).to be false
      expect(parent.errors[:base].join).to match(/not empty|children/i)
      expect(Folder.exists?(parent.id)).to be true
    end

    it "blocks destroy when stored files exist" do
      folder = build_folder
      folder.save!
      sf = folder.stored_files.build(company: company, name: "doc.pdf")
      sf.file.attach(io: StringIO.new("pdfdata"), filename: "doc.pdf", content_type: "application/pdf")
      sf.save!
      expect(folder.destroy).to be false
      expect(Folder.exists?(folder.id)).to be true
    end

    it "allows destroy when empty and is a root bucket" do
      folder = build_folder
      folder.save!
      expect { folder.destroy! }.to change(Folder, :count).by(-1)
    end
  end
end
