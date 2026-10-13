class BackfillNotificationTagsOwnerAllEmployees < ActiveRecord::Migration[8.0]
  def up
    Company.find_each do |company|
      all_company = NotificationTag.find_by(company_id: company.id, name: "All Company")
      all_employees = NotificationTag.find_by(company_id: company.id, name: "All Employees")

      if all_company && all_employees.nil?
        all_company.update!(name: "All Employees", description: "Broadcasts to every employee in the company.")
      elsif all_company && all_employees
        EmployeeNotificationTagAppointment.where(company_id: company.id, notification_tag_id: all_company.id).find_each do |sub|
          EmployeeNotificationTagAppointment.find_or_create_by!(
            company_id: company.id, employee_id: sub.employee_id, notification_tag_id: all_employees.id
          )
        end
        NotificationTagAppointment.where(company_id: company.id, notification_tag_id: all_company.id).update_all(notification_tag_id: all_employees.id)
        EmployeeNotificationTagAppointment.where(company_id: company.id, notification_tag_id: all_company.id).delete_all
        all_company.delete
      end

      NotificationTag.find_by(company_id: company.id, name: "Promotion")&.then do |promotion|
        EmployeeNotificationTagAppointment.where(company_id: company.id, notification_tag_id: promotion.id).delete_all
        NotificationTagAppointment.where(company_id: company.id, notification_tag_id: promotion.id).delete_all
        promotion.delete
      end
    end

    Company.find_each do |company|
      Seed::NotificationTagService.create_defaults!(company: company)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
