# frozen_string_literal: true

require "digest"

# Stable digest of an Import header contract. Key order is irrelevant and any
# value change produces a new digest, so a passing dry run is bound to the exact
# schema (target table + category + headers) it validated.
module Imports
  class SchemaDigest
    DIGEST_KEYS = %w[target_table category_id headers].freeze

    def self.call(schema)
      Digest::SHA256.hexdigest(JSON.generate(deep_sort(schema.slice(*DIGEST_KEYS))))
    end

    def self.deep_sort(value)
      case value
      when Hash
        value.keys.sort.each_with_object({}) { |key, sorted| sorted[key] = deep_sort(value[key]) }
      when Array
        value.map { |entry| deep_sort(entry) }
      else
        value
      end
    end
    private_class_method :deep_sort
  end
end
