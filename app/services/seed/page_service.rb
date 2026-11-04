# frozen_string_literal: true

# Seeds the company-level operating-page catalog and its location appointments.
# The catalog is keyed by purpose (PAGE_TYPES); branch/warehouse scope is a
# seed-time hint that decides which appointment table receives rows.
class Seed::PageService
  class << self
    def seed_defaults!(company:)
      Page.transaction do
        PAGE_TYPES.each_key do |page_type|
          page = company.pages.find_or_initialize_by(page_type: page_type, resolution: :desktop)
          next unless page.new_record?

          page.assign_attributes(
            name: label_for(company: company, page_type: page_type),
            description: "#{PAGE_TYPES.dig(page_type, :label)} page for #{company.name}",
            code: generate_code(company: company, page_type: page_type),
            metadata: { "roles" => [] },
            lifecycle_status: :active,
            workflow_status: :approved,
            permission_resource_name: "Page"
          )
          page.save!
        end

        company.branches.find_each { |branch| ensure_appointments_for_branch!(branch) }
        company.warehouses.find_each { |warehouse| ensure_appointments_for_warehouse!(warehouse) }
      end

      company.pages.order(:page_type).to_a
    end

    def ensure_appointments_for_branch!(branch)
      company = branch.company
      return [] unless company

      pages_for_scope(company, :branch).map do |page|
        BranchPageAppointment.find_or_create_by!(
          company: company,
          branch: branch,
          page: page
        ) do |appointment|
          apply_appointment_defaults(appointment, page, branch)
        end
      end
    end

    def ensure_appointments_for_warehouse!(warehouse)
      company = warehouse.company
      return [] unless company

      pages_for_scope(company, :warehouse).map do |page|
        PageWarehouseAppointment.find_or_create_by!(
          company: company,
          page: page,
          warehouse: warehouse
        ) do |appointment|
          apply_appointment_defaults(appointment, page, warehouse)
        end
      end
    end

    def ensure_appointments_for_page!(page)
      case appointment_scope(page.page_type)
      when :branch
        page.company.branches.find_each do |branch|
          BranchPageAppointment.find_or_create_by!(company: page.company, branch: branch, page: page) do |appointment|
            apply_appointment_defaults(appointment, page, branch)
          end
        end
      when :warehouse
        page.company.warehouses.find_each do |warehouse|
          PageWarehouseAppointment.find_or_create_by!(company: page.company, page: page, warehouse: warehouse) do |appointment|
            apply_appointment_defaults(appointment, page, warehouse)
          end
        end
      end
    end

    def create(
      company:,
      page_type:,
      resolution: :desktop,
      name: nil,
      description: nil,
      code: nil,
      metadata: { "roles" => [] },
      lifecycle_status: :active,
      workflow_status: :approved,
      permission_resource_name: "Page"
    )
      page = company.pages.find_or_initialize_by(page_type: page_type, resolution: resolution)
      if page.new_record?
        page.assign_attributes(
          name: name || label_for(company: company, page_type: page_type),
          description: description || "#{PAGE_TYPES.dig(page_type.to_sym, :label)} page for #{company.name}",
          code: code || generate_code(company: company, page_type: page_type),
          metadata: metadata,
          lifecycle_status: lifecycle_status,
          workflow_status: workflow_status,
          permission_resource_name: permission_resource_name
        )
        page.save!
      end
      ensure_appointments_for_page!(page)
      page
    end

    def page_types_for_scope(scope)
      PAGE_TYPES.select { |_page_type, config| config[:appointment_scope] == scope }.keys
    end

    def appointment_scope(page_type)
      PAGE_TYPES.dig(page_type.to_sym, :appointment_scope)
    end

    def label_for(company:, page_type:)
      PAGE_LABELS_BY_BUSINESS_TYPE
        .dig(company.business_type&.to_sym, page_type.to_sym) ||
        PAGE_TYPES.dig(page_type.to_sym, :label) ||
        page_type.to_s.humanize
    end

    def generate_code(company:, page_type:)
      prefix = PAGE_TYPES.dig(page_type.to_sym, :code_prefix) || "PG"
      "#{prefix}-#{company.id.first(8)}-#{SecureRandom.hex(2).upcase}"
    end

    private

    def pages_for_scope(company, scope)
      company.pages.where(page_type: page_types_for_scope(scope)).order(:page_type)
    end

    def apply_appointment_defaults(appointment, page, location)
      appointment.name = "#{page.name} at #{location.name}"
      appointment.code = "#{PAGE_TYPES.dig(page.page_type.to_sym, :code_prefix) || 'PG'}-#{location.id.first(8)}-#{SecureRandom.hex(2).upcase}"
      appointment.lifecycle_status = :active
      appointment.workflow_status = :active
      appointment.permission_resource_name = "Page"
      appointment.metadata = {}
    end
  end
end
