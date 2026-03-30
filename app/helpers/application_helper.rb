module ApplicationHelper
  def stimulus_controller
    [ controller_path.gsub("/", "--"), action_name ].join("--").dasherize
  end
end
