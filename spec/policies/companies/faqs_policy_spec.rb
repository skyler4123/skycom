# frozen_string_literal: true

require "rails_helper"

RSpec.describe Companies::FaqsPolicy do
  let(:company) { create(:company) }
  let(:employee) { company.employees.first }

  it "allows any employee to read the FAQ" do
    expect(described_class.new(employee, employee).show?).to be(true)
  end
end
