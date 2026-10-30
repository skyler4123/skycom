# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeeGroups::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "employee_groups" }
    let(:index_class) { EmployeeGroup }
    let(:record) do
      lambda do |company:, category:, **attrs|
        name = attrs.delete(:name)
        employee_group = Seed::EmployeeGroupService.create(
          company: company,
          category: category,
          name: name
        )
        employee_group.update!(attrs) if attrs.any?
        employee_group
      end
    end
  end
end
