# spec/models/record_comment_spec.rb
require "rails_helper"

RSpec.describe RecordComment, type: :model do
  describe "table" do
    it "uses record_comments" do
      expect(described_class.table_name).to eq("record_comments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:subject) }
    it { should have_many(:comment_mentions).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:body_markdown) }
    it { should validate_length_of(:body_markdown).is_at_most(20000) }
  end
end
