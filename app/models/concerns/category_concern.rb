# frozen_string_literal: true

# CategoryConcern — Atomic purpose: guarantees a category on create for
# category-scoped resources.
#
# Why it exists: records such as products, orders, and employees must always
# have a category so their property mapping/workflow can resolve.
# How it works: before_validation on create finds or creates the company's
# Category for this model's plural resource name and assigns it when missing.
# Main associations: none directly; requires the includer to belong_to :category
# and :company.
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
