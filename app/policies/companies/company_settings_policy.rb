# app/policies/companies/company_settings_policy.rb
#
# Owner-only update: ONLY the company owner (owner-role employee) may update
# Quick Links. Grants are deliberately ignored — the sidebar renders for
# everyone, but editing shared Quick Links is an owner action (mirrors
# RolesPolicy). Do NOT add CompanySetting update entries to seed
# role_definitions; they would be inert but misleading.
class Companies::CompanySettingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CompanySetting)
  end

  def update?
    record.owner_role?
  end
end
