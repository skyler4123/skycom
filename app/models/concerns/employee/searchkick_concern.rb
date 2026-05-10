module Employee::SearchkickConcern
  extend ActiveSupport::Concern

  included do
    searchkick word_start: [ :name, :email, :code, :job_title, :department ],
               searchable: [ :name, :email, :code, :description, :job_title, :department ],
               filterable: [ :company_id, :branch_id, :lifecycle_status, :workflow_status, :business_type ],
               callbacks: :async,
               settings: { number_of_shards: 1, number_of_replicas: 0 }

    def search_data
      # 1. Map standard attributes
      data = attributes.except("metadata", "updated_at")
      data[:is_discarded] = discarded?

      # 2. Map dynamic filters from Company contract (Forced to Strings)
      company_filters = company.filters&.dig("employee_filters") || []

      company_filters.each do |f|
        key = f["key"]
        if metadata.key?(key)
          # We use "attr_" prefix to avoid naming collisions with real columns
          data["attr_#{key}"] = metadata[key].to_s
        end
      end

      data
    end

    def self.search_for_company(query, company_id, options = {})
      options[:where] ||= {}
      options[:where][:company_id] = company_id
      options[:where][:is_discarded] = false
      search(query.presence || "*", options)
    end
  end
end
