Rails.application.configure do
  MissionControl::Jobs.base_controller_class = "JobsController"
  MissionControl::Jobs.http_basic_auth_user = "dev"
  MissionControl::Jobs.http_basic_auth_password = "secret"
end
