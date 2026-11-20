# frozen_string_literal: true

# Reception::GuestResolver — finds or creates the Customer behind a reception
# visit. The guest name is the match key; a blank existing description is filled
# with the visitor's company so the card and badge have a real organisation.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::GuestResolver
  def self.call(company:, branch:, name:, visitor_company:)
    new(company: company, branch: branch, name: name, visitor_company: visitor_company).call
  end

  def initialize(company:, branch:, name:, visitor_company:)
    @company = company
    @branch = branch
    @name = name
    @visitor_company = visitor_company
  end

  def call
    customer = company.customers.find_by(name: name)
    if customer
      customer.update!(description: visitor_company) if customer.description.blank?
      return customer
    end

    company.customers.create!(
      name: name,
      description: visitor_company,
      branch: branch,
      category: customer_category,
      lifecycle_status: :active,
      workflow_status: :confirmed,
      business_type: :individual
    )
  end

  private

  attr_reader :company, :branch, :name, :visitor_company

  def customer_category
    @customer_category ||= Seed::CategoryService.find_or_create_for(
      company: company,
      resource_name: "customers"
    )
  end
end
