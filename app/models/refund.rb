# frozen_string_literal: true

# Refund — Atomic purpose: a customer-refund request that follows a company's
# own approval process (workflow-bound, like Purchase).
#
# Why it exists: refunding money/goods needs an approval trail and audit log;
# each company configures its own process via a `refund_process` workflow
# attached to a category.
# How it works: belongs to company/branch/category/property_mapping; optional
# links to customer/order/invoice/transaction/product. before_validation binds
# the category's workflow; after_create records the submission log. Money/stock
# reversal is manual (see docs).
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch, :customer, :order, :invoice, :transaction,
# :payment_method, :product, :workflow_step (optional); has_many :workflow_step_logs (as: :subject).
class Refund < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  attr_accessor :created_by_employee, :skip_workflow

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :refund_type, { cash: 0, product: 1, service: 2, credit: 3 }, default: :cash

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer, optional: true
  belongs_to :order, optional: true
  belongs_to :invoice, optional: true
  belongs_to :source_transaction, class_name: "Transaction", foreign_key: :transaction_id, optional: true
  belongs_to :payment_method, optional: true
  belongs_to :product, optional: true
  belongs_to :workflow_step, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :workflow_step_logs, as: :subject, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :refund_type, presence: true
  validates :category, presence: true
  validates :property_mapping, presence: true

  before_validation :bind_category_workflow, on: :create
  after_create :record_submission_log

  private

  def bind_category_workflow
    return if workflow_step.present?
    return unless category.present?

    workflow = skip_workflow ? nil : category.default_workflow
    if workflow.nil? || workflow.workflow_steps.none?
      self.workflow_status = :draft if workflow_status.blank?
      return
    end

    self.workflow_step = workflow.workflow_steps.order(:position).first
    self.workflow_status = :pending if workflow_status.blank?
  end

  def record_submission_log
    return if workflow_step.nil?

    WorkflowStepLog.create!(
      company: company,
      workflow: workflow_step.workflow,
      workflow_step: workflow_step,
      subject: self,
      employee: created_by_employee,
      outcome: :submitted,
      metadata: { "from_step_id" => workflow_step.id }
    )
  end
end
