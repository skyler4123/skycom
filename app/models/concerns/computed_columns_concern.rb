# frozen_string_literal: true

# ComputedColumnsConcern — Atomic purpose: lets a model declare read-only index
# columns calculated from related data (e.g. Product#quantity summed from Stock).
#
# Why it exists: some columns users always want in index tables are not stored on
# the record itself. The model is the single owner of the key/name/type so Table
# Config and Property Mapping can display them without duplicating definitions.
# How it works: `computed_column` registers a method name + display metadata.
# `available_computed_columns` drops entries that collide with real DB columns
# (the real column always wins). `computed_column_values` calls each method, and
# `preload_computed_columns` is the batch-loading hook for index controllers.
# Main associations: none; include in models that own computed index columns.
module ComputedColumnsConcern
  extend ActiveSupport::Concern

  class_methods do
    def computed_columns
      @computed_columns ||= []
    end

    def computed_column(method_name, name:, type:)
      computed_columns << {
        "key" => method_name.to_s,
        "name" => name,
        "type" => type.to_s
      }
    end

    # A computed key must never shadow a real DB column. The real column wins,
    # so declarations that collide are excluded from the public catalog.
    def available_computed_columns
      computed_columns.reject { |column| column_names.include?(column["key"]) }
    end

    # Override when the computed method queries related data. The index
    # controller calls this once per page so cells do not trigger N+1 queries.
    def preload_computed_columns(_records)
      nil
    end
  end

  def computed_column_values
    self.class.available_computed_columns.each_with_object({}) do |column, values|
      values[column["key"]] = public_send(column["key"])
    end
  end
end
