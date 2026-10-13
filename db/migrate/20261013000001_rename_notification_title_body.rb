class RenameNotificationTitleBody < ActiveRecord::Migration[8.0]
  def change
    rename_column :notifications, :title, :name
    rename_column :notifications, :body, :description
  end
end
