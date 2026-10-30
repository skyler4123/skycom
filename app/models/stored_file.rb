# frozen_string_literal: true

# StoredFile — Atomic purpose: one uploaded file (Active Storage blob) owned by a
# company folder and optionally attached to a domain record.
#
# Why it exists: centralizes upload metadata, MIME/size validation, and chunk
# bookkeeping for data imports; the polymorphic attachable lets a file belong to
# a migration or another record without a per-domain table.
# How it works: has_one_attached :file; before_save syncs file_size,
# content_type, extension, and name from the blob. Validations enforce the same
# company for folder/attachable plus the ACCEPTABLE_STORED_FILE_TYPES and
# STORED_FILE_MAX_SIZES_BY_TYPE limits. Import chunk counters live in metadata
# via store_accessor (see docs/STORAGE.md, docs/DATA_IMPORT.md).
# Main associations: belongs_to :company (touch), :folder, :attachable
# (polymorphic, optional); has_one_attached :file.
class StoredFile < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :chunk_index, :row_count, :import_status,
                 :processed_rows, :created_rows, :updated_rows, :failed_rows

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { general: 0 }, prefix: true

  # --- Associations ---
  belongs_to :company, touch: true
  belongs_to :folder
  belongs_to :attachable, polymorphic: true, optional: true

  has_one_attached :file, dependent: :purge_later

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :folder, presence: true
  validate :folder_same_company
  validate :attachable_same_company
  validate :file_must_be_attached
  validate :acceptable_file

  # --- Callbacks ---
  before_save :sync_file_metadata

  def download_url
    return nil unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true, disposition: "attachment")
  end

  # Coarse upload category for a MIME type. Single source of truth for both
  # #max_size_for and Storage::StatisticsService (stats buckets).
  def self.file_category(content_type)
    ct = content_type.to_s
    return :image if ct.start_with?("image/")
    return :pdf if ct == "application/pdf"
    return :text if %w[text/plain text/csv].include?(ct)
    return :archive if %w[
      application/zip application/x-zip-compressed
      application/x-rar-compressed application/vnd.rar
    ].include?(ct)

    :office
  end

  private

  def folder_same_company
    return if folder.blank? || company_id.blank?

    errors.add(:folder, "must belong to the same company") unless folder.company_id == company_id
  end

  def attachable_same_company
    return if attachable.blank? || company_id.blank?
    return unless attachable.respond_to?(:company_id)

    errors.add(:attachable, "must belong to the same company") unless attachable.company_id == company_id
  end

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def acceptable_file
    return unless file.attached? && file.blob.present?

    content_type = file.blob.content_type
    unless ACCEPTABLE_STORED_FILE_TYPES.include?(content_type)
      errors.add(:file, "type #{content_type} is not allowed")
      return
    end

    limit = max_size_for(content_type)
    return if limit.blank?

    if file.blob.byte_size > limit
      errors.add(:file, "is too big (max #{limit / 1.megabyte}MB for this file type)")
    end
  end

  def max_size_for(content_type)
    STORED_FILE_MAX_SIZES_BY_TYPE[self.class.file_category(content_type)]
  end

  def sync_file_metadata
    return unless file.attached? && file.blob.present?

    self.file_size = file.blob.byte_size
    self.content_type = file.blob.content_type
    self.extension = file.blob.filename.extension_without_delimiter.downcase
    self.name = file.blob.filename.to_s if name.blank?
  end
end
