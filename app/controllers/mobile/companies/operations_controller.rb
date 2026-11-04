class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    branch_appointments = @company.branch_operation_appointments.includes(:operation, :branch).to_a
    warehouse_appointments = @company.operation_warehouse_appointments.includes(:operation, :warehouse).to_a

    @appointments = (branch_appointments + warehouse_appointments)
      .select { |appointment| appointment.operation.accessible_by?(@employee) }
      .sort_by do |appointment|
        [
          appointment.operation.name.to_s.downcase,
          appointment.is_a?(BranchOperationAppointment) ? 0 : 1
        ]
      end
  end
end
