# app/models/company_setting.rb
class CompanySetting < ApplicationRecord
  CREDENTIAL_COLUMNS = %w[credential_1 credential_2 credential_3].freeze

  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :sidebar_groups

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, { inactive: 0, active: 1 }, prefix: true, default: :inactive
  enum :business_type, { sidebar_groups: 0, s3_storage: 1 }

  encrypts :credential_1, :credential_2, :credential_3

  # --- Associations ---
  belongs_to :company, touch: true

  scope :active, -> { where(workflow_status: :active) }
  scope :active_sidebar, -> { active.where(business_type: :sidebar_groups) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :business_type, presence: true
  validates :workflow_status, presence: true
  validate :single_active_setting_constraint, if: :workflow_status_active?
  validate :sidebar_groups_shape

  def sidebar_groups
    super || []
  end

  # Resolves a logical credential reference stored in metadata, e.g.
  # metadata: { "s3" => { "access_key_ref" => "credential_1" } }.
  # Returns the decrypted value, or nil for unknown sections/refs.
  def credential_for(section, ref_key)
    section_data = metadata.is_a?(Hash) ? (metadata[section.to_s] || metadata[section.to_sym]) : nil
    return nil unless section_data.is_a?(Hash)

    column = section_data[ref_key.to_s] || section_data[ref_key.to_sym]
    return nil unless CREDENTIAL_COLUMNS.include?(column.to_s)

    public_send(column)
  end

  private

  def single_active_setting_constraint
    scope = self.class.where(company_id: company_id, business_type: business_type, workflow_status: :active)
    scope = scope.where.not(id: id) if persisted?
    scope = scope.where(discarded_at: nil) if has_attribute?(:discarded_at)

    if scope.exists?
      errors.add(:workflow_status, "There is already an active setting for this type on this resource.")
    end
  end

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
end
