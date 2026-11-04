# frozen_string_literal: true

# Seeds the company-level operation catalog and its location appointments.
# The catalog is keyed by purpose (OPERATION_TYPES); branch/warehouse scope is a
# seed-time hint that decides which appointment table receives rows.
class Seed::OperationService
  class << self
    def seed_defaults!(company:)
      Operation.transaction do
        OPERATION_TYPES.each_key do |operation_type|
          operation = company.operations.find_or_initialize_by(operation_type: operation_type, resolution: :desktop)
          next unless operation.new_record?

          operation.assign_attributes(
            name: label_for(company: company, operation_type: operation_type),
            description: "#{OPERATION_TYPES.dig(operation_type, :label)} operation for #{company.name}",
            code: generate_code(company: company, operation_type: operation_type),
            metadata: { "roles" => [] },
            lifecycle_status: :active,
            workflow_status: :approved,
            permission_resource_name: "Operation"
          )
          operation.save!
        end

        company.branches.find_each { |branch| ensure_appointments_for_branch!(branch) }
        company.warehouses.find_each { |warehouse| ensure_appointments_for_warehouse!(warehouse) }
      end

      company.operations.order(:operation_type).to_a
    end

    def ensure_appointments_for_branch!(branch)
      company = branch.company
      return [] unless company

      operations_for_scope(company, :branch).map do |operation|
        BranchOperationAppointment.find_or_create_by!(
          company: company,
          branch: branch,
          operation: operation
        ) do |appointment|
          apply_appointment_defaults(appointment, operation, branch)
        end
      end
    end

    def ensure_appointments_for_warehouse!(warehouse)
      company = warehouse.company
      return [] unless company

      operations_for_scope(company, :warehouse).map do |operation|
        OperationWarehouseAppointment.find_or_create_by!(
          company: company,
          operation: operation,
          warehouse: warehouse
        ) do |appointment|
          apply_appointment_defaults(appointment, operation, warehouse)
        end
      end
    end

    def ensure_appointments_for_operation!(operation)
      case appointment_scope(operation.operation_type)
      when :branch
        operation.company.branches.find_each do |branch|
          BranchOperationAppointment.find_or_create_by!(company: operation.company, branch: branch, operation: operation) do |appointment|
            apply_appointment_defaults(appointment, operation, branch)
          end
        end
      when :warehouse
        operation.company.warehouses.find_each do |warehouse|
          OperationWarehouseAppointment.find_or_create_by!(company: operation.company, operation: operation, warehouse: warehouse) do |appointment|
            apply_appointment_defaults(appointment, operation, warehouse)
          end
        end
      end
    end

    def create(
      company:,
      operation_type:,
      resolution: :desktop,
      name: nil,
      description: nil,
      code: nil,
      metadata: { "roles" => [] },
      lifecycle_status: :active,
      workflow_status: :approved,
      permission_resource_name: "Operation"
    )
      operation = company.operations.find_or_initialize_by(operation_type: operation_type, resolution: resolution)
      if operation.new_record?
        operation.assign_attributes(
          name: name || label_for(company: company, operation_type: operation_type),
          description: description || "#{OPERATION_TYPES.dig(operation_type.to_sym, :label)} operation for #{company.name}",
          code: code || generate_code(company: company, operation_type: operation_type),
          metadata: metadata,
          lifecycle_status: lifecycle_status,
          workflow_status: workflow_status,
          permission_resource_name: permission_resource_name
        )
        operation.save!
      end
      ensure_appointments_for_operation!(operation)
      operation
    end

    def operation_types_for_scope(scope)
      OPERATION_TYPES.select { |_operation_type, config| config[:appointment_scope] == scope }.keys
    end

    def appointment_scope(operation_type)
      OPERATION_TYPES.dig(operation_type.to_sym, :appointment_scope)
    end

    def label_for(company:, operation_type:)
      OPERATION_LABELS_BY_BUSINESS_TYPE
        .dig(company.business_type&.to_sym, operation_type.to_sym) ||
        OPERATION_TYPES.dig(operation_type.to_sym, :label) ||
        operation_type.to_s.humanize
    end

    def generate_code(company:, operation_type:)
      prefix = OPERATION_TYPES.dig(operation_type.to_sym, :code_prefix) || "OP"
      "#{prefix}-#{company.id.first(8)}-#{SecureRandom.hex(2).upcase}"
    end

    private

    def operations_for_scope(company, scope)
      company.operations.where(operation_type: operation_types_for_scope(scope)).order(:operation_type)
    end

    def apply_appointment_defaults(appointment, operation, location)
      appointment.name = "#{operation.name} at #{location.name}"
      appointment.code = "#{OPERATION_TYPES.dig(operation.operation_type.to_sym, :code_prefix) || 'OP'}-#{location.id.first(8)}-#{SecureRandom.hex(2).upcase}"
      appointment.lifecycle_status = :active
      appointment.workflow_status = :active
      appointment.permission_resource_name = "Operation"
      appointment.metadata = {}
    end
  end
end
