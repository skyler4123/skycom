class DropNotifications < ActiveRecord::Migration[8.0]
  def change
    drop_table :employee_notification_appointments, id: :uuid, default: -> { "uuidv7()" }
    drop_table :employee_notification_group_appointments, id: :uuid, default: -> { "uuidv7()" }
    drop_table :notification_tag_appointments, id: :uuid, default: -> { "uuidv7()" }
    drop_table :notification_group_tag_appointments, id: :uuid, default: -> { "uuidv7()" }
    drop_table :notifications, id: :uuid, default: -> { "uuidv7()" }
    drop_table :notification_groups, id: :uuid, default: -> { "uuidv7()" }
  end
end
