module ApplicationHelper
  def stimulus_controller
    [ controller_path.gsub("/", "--"), action_name ].join("--").dasherize
  end

  def server_data(data: nil, pagination: nil, flash: nil)
    "
      <script>
        window.ServerData = {
          data: #{ data&.html_safe || {} },
          pagination: #{ pagination&.to_json&.html_safe || {} },
          flash: #{ flash.to_hash.to_json.html_safe }
        };
      </script>
    "
  end
end
