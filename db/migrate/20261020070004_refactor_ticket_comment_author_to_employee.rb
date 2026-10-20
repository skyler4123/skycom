class RefactorTicketCommentAuthorToEmployee < ActiveRecord::Migration[8.0]
  def change
    rename_column :ticket_comments, :author_id, :employee_id
    remove_column :ticket_comments, :author_type, :string
    add_foreign_key :ticket_comments, :employees, column: :employee_id
  end
end