class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    branch_appointments = @company.branch_page_appointments.includes(:page, :branch).to_a
    warehouse_appointments = @company.page_warehouse_appointments.includes(:page, :warehouse).to_a

    @appointments = (branch_appointments + warehouse_appointments)
      .select { |appointment| appointment.page.accessible_by?(@employee) }
      .sort_by do |appointment|
        [
          appointment.page.name.to_s.downcase,
          appointment.is_a?(BranchPageAppointment) ? 0 : 1
        ]
      end
  end
end
