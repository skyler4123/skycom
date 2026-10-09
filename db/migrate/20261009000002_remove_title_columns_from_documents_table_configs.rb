class RemoveTitleColumnsFromDocumentsTableConfigs < ActiveRecord::Migration[8.0]
  def up
    # documents.title is gone — stale TableConfigs carrying a title column would
    # render empty cells and 503 keyword search (title is no longer searchable).
    TableConfig.where(resource_name: "documents").find_each do |config|
      columns = config.metadata["columns"]
      next unless columns.is_a?(Array)

      pruned = columns.reject { |col| col["key"] == "title" }
      next if pruned.length == columns.length

      config.update!(metadata: config.metadata.merge("columns" => pruned))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
