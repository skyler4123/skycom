module Product::SearchkickConcern
  extend ActiveSupport::Concern

  included do
    searchkick word_start: [ :name, :sku, :barcode, :code, :model_number ],
               searchable: [ :name, :sku, :barcode, :description, :model_number, :brand_name ],
               filterable: [ :company_id, :branch_id, :brand_id, :category_id, :lifecycle_status, :visibility ],
               callbacks: :async,
               settings: { number_of_shards: 1, number_of_replicas: 0 }

    def search_data
      data = attributes.except("metadata", "updated_at")
      data[:is_discarded] = discarded?
      data[:brand_name] = brand&.name # Join for searching by brand name

      # Dynamic filters from Company contract
      company_filters = company.filters&.dig("product_filters") || []

      company_filters.each do |f|
        key = f["key"]
        data["attr_#{key}"] = metadata[key].to_s if metadata.key?(key)
      end

      data
    end
  end
end
