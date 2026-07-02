module PropertyMappingConcern
  extend ActiveSupport::Concern

  included do
    include DynamicValidationConcern
    before_validation :ensure_property_mapping, on: :create
    before_validation :auto_populate_property_fields, on: :create
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
