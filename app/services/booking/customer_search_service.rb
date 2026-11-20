# frozen_string_literal: true

# Booking::CustomerSearchService — typeahead lookup for the reservation form.
# Text search is Meilisearch-only; the DB loads only the matching ids.
# Docs: docs/OPERATIONS.md §7, docs/MEILISEARCH.md
class Booking::CustomerSearchService
  LIMIT = 10

  def self.call(company:, query:)
    new(company: company, query: query).call
  end

  def initialize(company:, query:)
    @company = company
    @query = query.to_s.strip
  end

  def call
    return [] if query.length < 2

    result = Customer.ms_raw_search(
      query,
      filter: %(company_id = "#{company.id}"),
      limit: LIMIT
    )
    ids = Array(result["hits"]).map { |hit| hit["id"] }
    return [] if ids.empty?

    company.customers.where(id: ids).in_order_of(:id, ids).map do |customer|
      {
        id: customer.id,
        name: customer.name,
        code: customer.code,
        email: customer.email
      }
    end
  end

  private

  attr_reader :company, :query
end
