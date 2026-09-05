# spec/services/client_cache/enums_builder_spec.rb
require "rails_helper"

RSpec.describe ClientCache::EnumsBuilder do
  it "exposes business_types for every select-rendering resource" do
    enums = described_class.build
    %w[employee branch department brand facility category product service order customer].each do |resource|
      expect(enums.fetch(resource.to_sym)).to be_a(Hash)
    end
    expect(enums.dig(:branch, :business_types).map { |t| t[:value] }).to include("warehouse")
    expect(enums.dig(:category, :resource_names)).to include("products")
    expect(enums.dig(:order, :currencies).map { |c| c[:value] }).to include("usd", "vnd")
  end
end
