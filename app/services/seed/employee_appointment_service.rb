class Seed::EmployeeAppointmentService
  ROUTES = {
    "Article" => [ "ArticleEmployeeAppointmentService", :article ],
    "ArticleGroup" => [ "ArticleGroupEmployeeAppointmentService", :article_group ],
    "Customer" => [ "CustomerEmployeeAppointmentService", :customer ],
    "Department" => [ "DepartmentEmployeeAppointmentService", :department ],
    "Document" => [ "DocumentEmployeeAppointmentService", :document ],
    "DocumentGroup" => [ "DocumentGroupEmployeeAppointmentService", :document_group ],
    "Employee" => [ "EmployeeEmployeeAppointmentService", :related_employee ],
    "EmployeeGroup" => [ "EmployeeEmployeeGroupAppointmentService", :employee_group ],
    "Event" => [ "EmployeeEventAppointmentService", :event ],
    "EventGroup" => [ "EmployeeEventGroupAppointmentService", :event_group ],
    "Exam" => [ "EmployeeExamAppointmentService", :exam ],
    "Facility" => [ "EmployeeFacilityAppointmentService", :facility ],
    "Notification" => [ "EmployeeNotificationAppointmentService", :notification ],
    "NotificationGroup" => [ "EmployeeNotificationGroupAppointmentService", :notification_group ],
    "OrderGroup" => [ "EmployeeOrderGroupAppointmentService", :order_group ],
    "Product" => [ "EmployeeProductAppointmentService", :product ],
    "Project" => [ "EmployeeProjectAppointmentService", :project ],
    "ProjectGroup" => [ "EmployeeProjectGroupAppointmentService", :project_group ],
    "Service" => [ "EmployeeServiceAppointmentService", :service ],
    "Setting" => [ "EmployeeSettingAppointmentService", :setting ],
    "SettingGroup" => [ "EmployeeSettingGroupAppointmentService", :setting_group ],
    "Task" => [ "EmployeeTaskAppointmentService", :task ],
    "TaskGroup" => [ "EmployeeTaskGroupAppointmentService", :task_group ]
  }.freeze

  def self.new(
    company:,
    employee:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or employee provided." if company.nil? || employee.nil?

    route = ROUTES.fetch(appoint_to.class.name) do
      raise "Cannot route EmployeeAppointment for #{appoint_to.class.name}: no atomic pair table."
    end
    service_name, pair_key = route
    Seed.const_get(service_name).new(
      company: company,
      employee: employee,
      pair_key => appoint_to,
      name: name,
      description: description,
      code: code,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
