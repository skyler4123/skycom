class RemoveTitleContentFromDocumentsAndDropDeadModels < ActiveRecord::Migration[8.0]
  def change
    # Document: name is the title now; body_markdown is the body. Keep name as-is (no backfill).
    remove_column :documents, :title, :string
    remove_column :documents, :content, :json
    # DocumentGroup is deleted, so its NOT NULL FK cannot survive.
    remove_reference :documents, :document_group, type: :uuid, foreign_key: true

    drop_table :article_group_tag_appointments
    drop_table :article_tag_appointments
    drop_table :article_employee_appointments
    drop_table :article_group_employee_appointments
    drop_table :document_group_tag_appointments
    drop_table :document_group_employee_appointments
    drop_table :articles
    drop_table :article_groups
    drop_table :document_groups
  end
end
