module User::SearchConcern
  extend ActiveSupport::Concern

  INDEXED_COLUMNS = %w[
    id email username name first_name last_name phone_number
    system_role country lifecycle_status workflow_status business_type
  ].freeze

  SEARCHABLE_COLUMNS = %w[email username name first_name last_name phone_number].freeze

  FILTERABLE_COLUMNS = %w[system_role country workflow_status business_type].freeze

  included do
    include Meilisearch::Rails

    indexed_columns    = column_names & INDEXED_COLUMNS
    searchable_columns = column_names & SEARCHABLE_COLUMNS
    filterable_columns = column_names & FILTERABLE_COLUMNS

    meilisearch(
      synchronous: false,
      enqueue: ->(record, remove) { MeilisearchIndexJob.perform_later(record.class.name, record.id, remove) }
    ) do
      attribute(*indexed_columns)

      searchable_attributes searchable_columns
      filterable_attributes filterable_columns
    end
  end
end
