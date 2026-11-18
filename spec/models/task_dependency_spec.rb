# spec/models/task_dependency_spec.rb
require "rails_helper"

RSpec.describe TaskDependency, type: :model do
  describe "table" do
    it "uses task_dependencies" do
      expect(described_class.table_name).to eq("task_dependencies")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:predecessor_task).class_name("Task") }
    it { should belong_to(:successor_task).class_name("Task") }
  end

  describe "validations" do
    it "declares predecessor_task_id uniqueness scoped to successor_task_id" do
      validator = described_class.validators_on(:predecessor_task_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[successor_task_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:dependency_type).with_prefix(true).with_values(finish_to_start: 0, start_to_start: 1, finish_to_finish: 2, start_to_finish: 3) }
  end

describe "precedence" do
  it "refuses a task that depends on itself" do
    id = SecureRandom.uuid
    dependency = described_class.new(predecessor_task_id: id, successor_task_id: id)
    dependency.valid?

    expect(dependency.errors[:successor_task]).to include("cannot depend on itself")
  end
end
end
