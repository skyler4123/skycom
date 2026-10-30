# frozen_string_literal: true

# PropertyMappingConcern — Atomic purpose: binds a record to its category's
# PropertyMapping and applies the mapping's dynamic validations.
#
# Why it exists: category-scoped records must use the category's property schema,
# and the mapping must be assigned before validation rather than by every caller.
# How it works: before_validation assigns category.default_property_mapping on
# create, includes DynamicValidationConcern, auto-populates empty property slots,
# and validates that the mapping belongs to the record's category.
# Main associations: none directly; requires the includer to belong_to :category
# and :property_mapping.
module PropertyMappingConcern
  extend ActiveSupport::Concern

  included do
    include DynamicValidationConcern
    before_validation :ensure_property_mapping, on: :create
    before_validation :auto_populate_property_fields, on: [ :create, :update ]
    validate :category_matches_property_mapping_category
  end

  private

  def ensure_property_mapping
    return if property_mapping.present?
    return unless category.present?

    self.property_mapping = category.default_property_mapping
  end

  def category_matches_property_mapping_category
    return unless category.present? && property_mapping.present?

    if category_id != property_mapping.category_id
      errors.add(:property_mapping, "category must match record's category")
    end
  end
end
