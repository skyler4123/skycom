
module CompanyGroup::RetailConcern
  extend ActiveSupport::Concern

  included do
    def branches
      companies
    end

    def departments
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
  end
end
