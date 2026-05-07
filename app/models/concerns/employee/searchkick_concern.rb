module Employee::SearchkickConcern
  extend ActiveSupport::Concern

  included do
    # 1. Configuration: Scoping and Performance
    searchkick word_start: [ :name, :email, :code ],
               searchable: [ :name, :email, :code, :description ],
               filterable: [ :company_id, :branch_id, :lifecycle_status, :workflow_status, :business_type ],
               callbacks: :async,
               settings: {
                 number_of_shards: 1,
                 number_of_replicas: 0
               }

    # 2. Search Data: Map the model to Elasticsearch
    def search_data
      {
        id: id,
        company_id: company_id,
        branch_id: branch_id,
        name: name,
        email: email,
        code: code,
        description: description,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        is_discarded: discarded?,
        # Flatten metadata for searching
        # Example: { "size": "XL" } becomes searchable properties
        metadata: metadata,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    # 3. Custom Logic: Scoping helper
    # Ensures we never accidentally search across the whole ERP
    def self.search_for_company(query, company_id, options = {})
      options[:where] ||= {}
      options[:where][:company_id] = company_id
      options[:where][:is_discarded] = false # Default to kept employees

      search(query, options)
    end
  end
end
