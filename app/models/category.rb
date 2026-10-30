# frozen_string_literal: true

# Category — Atomic purpose: tenant-scoped classification row that anchors the
# dynamic schema (property mapping, table config, workflow) for one resource
# family.
#
# Why it exists: each company defines its own categories per resource, and the
# category is what carries the dynamic property/table/workflow configuration for
# records such as products, services, orders, and employees (see
# docs/CATEGORY_DYNAMIC_SCHEMA.md).
# How it works: belongs to a company; after_create creates the default property
# mapping. #default_property_mapping / #default_table_config / #default_workflow
# expose the first configured child, and CategoryConcern wires records to the
# category's dynamic schema.
# Main associations: belongs_to :company (touch); has_many :property_mappings,
# :table_configs, :workflows (dependent: :destroy); has_many resource records
# (employees, products, services, branches, ...) with dependent: :nullify.
class Category < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company, touch: true

  has_many :property_mappings, dependent: :destroy
  has_many :table_configs, dependent: :destroy
  has_many :workflows, dependent: :destroy

  has_many :employee_groups, dependent: :nullify
  has_many :employees, dependent: :nullify
  has_many :departments, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :services, dependent: :nullify
  has_many :branches, dependent: :nullify
  has_many :brands, dependent: :nullify
  has_many :customers, dependent: :nullify
  has_many :facilities, dependent: :nullify
  has_many :stocks, dependent: :nullify
  validates :name, uniqueness: { scope: [ :company_id, :resource_name ] }
  after_create :create_default_property_mapping

  def default_property_mapping
    property_mappings.first
  end

  def default_table_config
    table_configs.first
  end

  def default_workflow
    workflows.first
  end

  private

  def create_default_property_mapping
    property_mappings.create!(company: company, name: "#{name} mappings")
  end
end
