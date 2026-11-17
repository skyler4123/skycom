# config/initializers/meilisearch.rb

Meilisearch::Rails.configuration = {
  meilisearch_url: MEILISEARCH_HOST,
  meilisearch_api_key: MEILISEARCH_API_KEY,
  # Indexes are env-scoped (e.g. Product_development / Product_test) so local rspec
  # ms_clear_index! hooks can never wipe dev data on the shared server (docs/MEILISEARCH.md §8).
  per_environment: true
}

if Rails.env.test? && TEST_ENV_NUMBER.present?
  module Meilisearch
    module Rails
      module ClassMethods
        def ms_index_uid(options = nil)
          options ||= meilisearch_options
          global_options = Meilisearch::Rails.configuration

          name = options[:index_uid] || model_name.to_s.gsub("::", "_")
          name = "#{name}_#{::Rails.env}" if global_options[:per_environment]

          # parallel_tests isolation
          suffix = TEST_ENV_NUMBER.to_s
          name = "#{name}#{suffix}" unless suffix.empty?

          name
        end
      end
    end
  end
end
