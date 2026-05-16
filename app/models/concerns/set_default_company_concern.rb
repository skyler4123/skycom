# frozen_string_literal: true

# == Purpose:
# Automatically sets +company_id+ on Appointment records by deriving it from
# the associated resource (Role, Policy, Tag, Service, Task, etc.).
#
# This ensures ABAC permission checks work correctly since they depend on
# +company_id+ being present for multi-tenant security. Without this concern,
# creating an appointment like +RoleAppointment.create!(role: some_role)+ would
# fail because company_id would be nil.
#
# == How It Works:
# 1. Extracts the resource name from the model class name
#    - RoleAppointment → "role"
#    - PolicyAppointment → "policy"
#    - TagAppointment → "tag"
#    - ServiceGroupAppointment → "service_group"
# 2. Calls the corresponding association to get the resource
# 3. Assigns the resource's company_id to the appointment
# 4. Only sets company_id if not already present (manual assignment takes precedence)
#
# == Usage:
# Include this concern in any *Appointment model that has a singular resource
# association (e.g., belongs_to :role, belongs_to :policy, belongs_to :tag)
#
# == Example:
#   class RoleAppointment < ApplicationRecord
#     include SetDefaultCompanyConcern
#     belongs_to :role  # Will derive company_id from role.company_id
#   end
#
module SetDefaultCompanyConcern
  extend ActiveSupport::Concern

  included do
    before_validation :set_default_company_from_resource
  end

  private

  # Sets company_id from the associated resource if not already present.
  # Guard clauses:
  #   1. Skip if company association is already loaded/present
  #   2. Skip if company_id column is already set
  #   3. Skip if no associated resource exists
  #   4. Otherwise, assign company_id from the resource
  def set_default_company_from_resource
    return if company.present?
    return if company_id.present?

    resource = find_resource_association
    return if resource.blank?

    self.company_id = resource.company_id
  end

  # Dynamically derives the resource association name from the model class name.
  # Examples:
  #   - "RoleAppointment".gsub("Appointment", "").underscore → "role"
  #   - "PolicyAppointment".gsub("Appointment", "").underscore → "policy"
  #   - "ServiceGroupAppointment".gsub("Appointment", "").underscore → "service_group"
  #
  # Returns nil if:
  #   - The derived name is blank
  #   - The model doesn't respond to that association name
  def find_resource_association
    resource_name = self.class.name.gsub("Appointment", "").underscore

    return nil if resource_name.blank?
    return nil unless respond_to?(resource_name)

    public_send(resource_name)
  end
end
