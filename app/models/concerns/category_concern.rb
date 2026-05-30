module CategoryConcern
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_category, on: :create
  end

  private

  def ensure_category
    return if category.present?
    return unless company.present?

    self.category = Category.find_or_create_by!(
      company: company,
      resource_name: self.class.model_name.plural
    ) { |cat| cat.name = self.class.model_name.human.pluralize }
  end
end
