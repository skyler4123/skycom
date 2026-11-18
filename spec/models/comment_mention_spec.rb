# spec/models/comment_mention_spec.rb
require "rails_helper"

RSpec.describe CommentMention, type: :model do
  describe "table" do
    it "uses comment_mentions" do
      expect(described_class.table_name).to eq("comment_mentions")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:record_comment) }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it "declares employee_id uniqueness scoped to record_comment_id" do
      validator = described_class.validators_on(:employee_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[record_comment_id])
    end
  end
end
