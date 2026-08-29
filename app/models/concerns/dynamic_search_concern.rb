module DynamicSearchConcern
  extend ActiveSupport::Concern

  PROPERTY_STRING_COLUMNS = (1..10).map { |i| "property_string_#{i}" }.freeze
  PROPERTY_INTEGER_COLUMNS = (1..20).map { |i| "property_integer_#{i}" }.freeze
  PROPERTY_DECIMAL_COLUMNS = (1..10).map { |i| "property_decimal_#{i}" }.freeze
  PROPERTY_BOOLEAN_COLUMNS = (1..10).map { |i| "property_boolean_#{i}" }.freeze
  PROPERTY_DATETIME_COLUMNS = (1..10).map { |i| "property_datetime_#{i}" }.freeze

  PROPERTY_COLUMNS = (PROPERTY_STRING_COLUMNS + PROPERTY_INTEGER_COLUMNS +
    PROPERTY_DECIMAL_COLUMNS + PROPERTY_BOOLEAN_COLUMNS + PROPERTY_DATETIME_COLUMNS).freeze

  STANDARD_COLUMNS = %w[id company_id category_id branch_id name description code workflow_status business_type].freeze

  included do
    include Meilisearch::Rails

    standard_columns  = column_names & STANDARD_COLUMNS
    string_columns    = column_names & PROPERTY_STRING_COLUMNS
    number_columns    = column_names & (PROPERTY_INTEGER_COLUMNS + PROPERTY_DECIMAL_COLUMNS)
    boolean_columns   = column_names & PROPERTY_BOOLEAN_COLUMNS
    datetime_columns  = column_names & PROPERTY_DATETIME_COLUMNS

    indexed_attributes = standard_columns + string_columns + number_columns + boolean_columns + datetime_columns
    searchable_columns = (standard_columns & %w[name description code]) + string_columns + number_columns
    filterable_columns = (standard_columns & %w[company_id category_id branch_id workflow_status business_type]) +
      number_columns + boolean_columns + datetime_columns

    meilisearch(
      synchronous: false,
      enqueue: ->(record, remove) { MeilisearchIndexJob.perform_later(record.class.name, record.id, remove) }
    ) do
      attribute(*indexed_attributes)

      searchable_attributes searchable_columns
      filterable_attributes filterable_columns
    end
  end
end
