# app/models/setting.rb
class Setting < ApplicationRecord
  include TagConcern

  store_accessor :metadata, :sidebar_groups

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
  has_many :employee_setting_appointments, dependent: :destroy
  has_many :employees, through: :employee_setting_appointments

  # --- Scopes ---
  scope :company_level, -> { where(appoint_to_type: "Company") }
  scope :employee_level, -> { where(appoint_to_type: "Employee") }
  scope :dynamic_sidebar, -> { where(code: DYNAMIC_SIDEBAR_CODE) }
  scope :personal_sidebar, -> { where(code: PERSONAL_SIDEBAR_CODE) }

  # --- Validations ---
  validates :code, uniqueness: { scope: [ :company_id, :appoint_to_type, :appoint_to_id ] }, allow_nil: true
  validate :sidebar_groups_shape

  # --- Callbacks ---
  before_validation :derive_company_from_appoint_to

  def sidebar_groups
    super || []
  end

  private

  def sidebar_groups_shape
    groups = metadata.is_a?(Hash) ? metadata["sidebar_groups"] : nil
    groups = [] if groups.nil?
    unless groups.is_a?(Array)
      errors.add(:sidebar_groups, "must be an array")
      return
    end

    groups.each_with_index do |group, gi|
      unless group.is_a?(Hash)
        errors.add(:sidebar_groups, "group #{gi + 1} must be an object")
        next
      end
      name = group["name"] || group[:name]
      if name.to_s.strip.empty?
        errors.add(:sidebar_groups, "group #{gi + 1} must have a name")
      end
      items = group["items"] || group[:items] || []
      unless items.is_a?(Array)
        errors.add(:sidebar_groups, "group '#{name}' items must be an array")
        next
      end
      items.each_with_index do |item, ii|
        unless item.is_a?(Hash)
          errors.add(:sidebar_groups, "group '#{name}' item #{ii + 1} must be an object")
          next
        end
        item_name = item["name"] || item[:name]
        item_url = item["url"] || item[:url]
        if item_name.to_s.strip.empty?
          errors.add(:sidebar_groups, "group '#{name}' item #{ii + 1} must have a name")
        end
        if item_url.to_s.strip.empty?
          errors.add(:sidebar_groups, "group '#{name}' item #{ii + 1} must have a url")
        elsif item_url.to_s.strip.downcase.start_with?("javascript:")
          errors.add(:sidebar_groups, "group '#{name}' item #{ii + 1} url is not allowed")
        end
      end
    end
  end

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
