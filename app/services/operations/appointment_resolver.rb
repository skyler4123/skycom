# frozen_string_literal: true

module Operations
  # Resolves the appointment that an operation should run against.
  # Explicit location params win; otherwise fall back to the employee's branch
  # (branch operations) or a warehouse under that branch (warehouse operations).
  class AppointmentResolver
    def self.call(company:, operation:, employee:, branch_id: nil, warehouse_id: nil)
      case OPERATION_TYPES.dig(operation.operation_type.to_sym, :appointment_scope)
      when :branch
        resolve_branch(company, operation, employee, branch_id)
      when :warehouse
        resolve_warehouse(company, operation, employee, warehouse_id)
      end
    end

    class << self
      private

      def resolve_branch(company, operation, employee, branch_id)
        if branch_id.present?
          operation.branch_operation_appointments.find_by(company_id: company.id, branch_id: branch_id)
        else
          operation.branch_operation_appointments.active.find_by(
            company_id: company.id,
            branch_id: employee.branch_id
          )
        end
      end

      def resolve_warehouse(company, operation, employee, warehouse_id)
        if warehouse_id.present?
          operation.operation_warehouse_appointments.find_by(company_id: company.id, warehouse_id: warehouse_id)
        else
          warehouse_ids = employee.branch ? employee.branch.warehouse_ids : company.warehouse_ids
          operation.operation_warehouse_appointments.active.where(
            company_id: company.id,
            warehouse_id: warehouse_ids
          ).first
        end
      end
    end
  end
end
