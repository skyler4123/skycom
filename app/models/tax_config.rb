# frozen_string_literal: true

class TaxConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  store_accessor :metadata,
    :date_basis,
    :include_invoices,
    :include_purchases,
    :include_stock_exports,
    :excluded_invoice_statuses,
    :excluded_purchase_statuses,
    :stock_export_business_types,
    :branch_ids
  belongs_to :company

  validates :company_id, uniqueness: true


  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.metadata = {} if metadata.blank?
    self.date_basis = "created_at" if date_basis.blank?
    self.include_invoices = true if include_invoices.nil?
    self.include_purchases = true if include_purchases.nil?
    self.include_stock_exports = true if include_stock_exports.nil?
    self.excluded_invoice_statuses = [] if excluded_invoice_statuses.nil?
    self.excluded_purchase_statuses = [] if excluded_purchase_statuses.nil?
    self.stock_export_business_types = [ "sale" ] if stock_export_business_types.nil?
    self.branch_ids = [] if branch_ids.nil?
  end

  def self.for_company!(company)
    find_by(company: company) || begin
      create!(company: company)
    rescue ActiveRecord::RecordNotUnique
      find_by!(company: company)
    end
  end
end
