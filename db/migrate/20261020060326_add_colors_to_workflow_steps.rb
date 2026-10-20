class AddColorsToWorkflowSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :workflow_steps, :text_color, :string
    add_column :workflow_steps, :background_color, :string
  end
end
