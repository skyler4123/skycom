# frozen_string_literal: true

# ComputedColumns — Atomic purpose: resolves a resource name to the model that
# owns its computed index-column catalog.
#
# Why it exists: Table Config and Property Mapping are per-category, while
# computed columns are per-model. This module is the single lookup point that
# turns a category's `resource_name` (e.g. "products") into Product so both
# editors can display the same read-only catalog.
# How it works: `model_for` safely constantizes the resource name and requires an
# ApplicationRecord subclass; `for` returns only models that include
# ComputedColumnsConcern and their `available_computed_columns`.
# Main associations: none.
module ComputedColumns
  def self.for(resource_name)
    model = model_for(resource_name)
    return nil unless model&.respond_to?(:available_computed_columns)

    model.available_computed_columns
  end

  def self.model_for(resource_name)
    klass = resource_name.to_s.classify.safe_constantize
    klass if klass.is_a?(Class) && klass < ApplicationRecord
  end
end
