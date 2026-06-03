module PropertyMappingConcern
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_property_mapping, on: :create
  end

  private

  def ensure_property_mapping
    return if property_mapping.present?
    return unless category.present?

    self.property_mapping = category.property_mapping
  end
end
