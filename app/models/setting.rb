# app/models/setting.rb
class Setting < ApplicationRecord
  include TagConcern

  store_accessor :metadata, :sidebar_items

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    system: 0,
    company: 1,
    branch: 2,
    employee: 3,
    department: 4
  }

  # --- Associations ---
  belongs_to :setting_group, optional: true
  belongs_to :company, touch: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  # --- Scopes ---
  scope :company_level, -> { where(appoint_to_type: "Company") }

  # --- Callbacks ---
  before_validation :derive_company_from_appoint_to

  private

  def derive_company_from_appoint_to
    return if company_id.present?
    return unless appoint_to

    self.company_id = if appoint_to.is_a?(Company)
      appoint_to.id
    elsif appoint_to.respond_to?(:company_id)
      appoint_to.company_id
    end
  end
end
