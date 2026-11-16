Rails.application.configure do
  MissionControl::Jobs.base_controller_class = "JobsController"
  MissionControl::Jobs.http_basic_auth_user = MISSION_CONTROL_USER
  MissionControl::Jobs.http_basic_auth_password = MISSION_CONTROL_PASSWORD
end
