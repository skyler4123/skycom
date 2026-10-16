class DropSettingsTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :employee_setting_group_appointments, if_exists: true
    drop_table :employee_setting_appointments, if_exists: true
    drop_table :setting_group_tag_appointments, if_exists: true
    drop_table :setting_tag_appointments, if_exists: true
    drop_table :settings, if_exists: true
    drop_table :setting_groups, if_exists: true
  end
end
