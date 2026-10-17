class Folder < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { general: 0 }, prefix: true

  # --- Associations ---
  belongs_to :company, touch: true
  belongs_to :parent, class_name: "Folder", optional: true, foreign_key: :parent_id, inverse_of: :children
  # NOTE: no dependent option — the before_destroy guard below is the single
  # gate so the 422 carries one friendly message (restrict_with_error would
  # halt first with Rails' generic text and hide it).
  has_many :children, class_name: "Folder", foreign_key: :parent_id, inverse_of: :parent
  has_many :stored_files

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: [ :company_id, :parent_id ] }, length: { maximum: 255 }
  validate :parent_same_company
  validate :parent_not_self
  validate :parent_not_descendant

  # --- Callbacks ---
  before_destroy :prevent_destroy_if_not_empty

  private

  def parent_same_company
    return if parent.blank? || company_id.blank?

    errors.add(:parent, "must belong to the same company") unless parent.company_id == company_id
  end

  def parent_not_self
    return if parent.blank? || id.blank?

    errors.add(:parent, "cannot be itself") if parent_id == id
  end

  def parent_not_descendant
    return if parent.blank? || id.blank?

    ancestor = parent
    while ancestor
      if ancestor.id == id
        errors.add(:parent, "cannot be a descendant (cycle detected)")
        break
      end
      ancestor = ancestor.parent
    end
  end

  def prevent_destroy_if_not_empty
    if children.exists? || stored_files.exists?
      errors.add(:base, "Cannot delete a folder that is not empty. Remove children and files first.")
      throw(:abort)
    end
  end
end
