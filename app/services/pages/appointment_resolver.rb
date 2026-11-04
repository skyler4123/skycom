# frozen_string_literal: true

module Pages
  # Resolves the appointment that an operation page should run against.
  # Explicit location params win; otherwise fall back to the employee's branch
  # (branch pages) or a warehouse under that branch (warehouse pages).
  class AppointmentResolver
    def self.call(company:, page:, employee:, branch_id: nil, warehouse_id: nil)
      case PAGE_TYPES.dig(page.page_type.to_sym, :appointment_scope)
      when :branch
        resolve_branch(company, page, employee, branch_id)
      when :warehouse
        resolve_warehouse(company, page, employee, warehouse_id)
      end
    end

    class << self
      private

      def resolve_branch(company, page, employee, branch_id)
        if branch_id.present?
          page.branch_page_appointments.find_by(company_id: company.id, branch_id: branch_id)
        else
          page.branch_page_appointments.active.find_by(
            company_id: company.id,
            branch_id: employee.branch_id
          )
        end
      end

      def resolve_warehouse(company, page, employee, warehouse_id)
        if warehouse_id.present?
          page.page_warehouse_appointments.find_by(company_id: company.id, warehouse_id: warehouse_id)
        else
          warehouse_ids = employee.branch ? employee.branch.warehouse_ids : company.warehouse_ids
          page.page_warehouse_appointments.active.where(
            company_id: company.id,
            warehouse_id: warehouse_ids
          ).first
        end
      end
    end
  end
end
