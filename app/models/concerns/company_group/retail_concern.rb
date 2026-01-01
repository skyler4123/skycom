
module CompanyGroup::RetailConcern
  extend ActiveSupport::Concern

  included do
    def branches
      companies
    end

    def cached_departments
      # 1. Define the relation
      scope = employee_groups.joins(:category).where(categories: { name: "Department" })

      # 2. Generate a key based on the collection's state
      # Rails' `cache_key_with_version` automatically runs a light query:
      # SELECT COUNT(*) AND MAX(updated_at)
      cache_key = scope.cache_key_with_version

      # 3. Fetch using that specific key
      Rails.cache.fetch([ "departments", cache_key ]) do
        scope.to_a
      end
    end

    def cached_products
      # Similar caching approach for products
      scope = self.products
      cache_key = scope.cache_key_with_version
      Rails.cache.fetch([ "products", cache_key ]) do
        scope.to_a
      end
    end

    def cached_orders
      # Similar caching approach for orders
      scope = self.orders
      cache_key = scope.cache_key_with_version
      Rails.cache.fetch([ "orders", cache_key ]) do
        scope.to_a
      end
    end
  end
end
